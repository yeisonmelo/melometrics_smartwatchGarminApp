using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.Sensor as Snsr;
using Toybox.ActivityMonitor as ActivityMonitor;
using Toybox.ActivityRecording as ActivityRecording;
using Toybox.Activity as Activity;


class OneMileWalkTestView extends ParentView {

	var genero;
	var edad;
	var peso;
	var heartRate;
	var distanciaRecorrer; 
	var distanciaInicioActivity;
	var distanciaDetenerActivity;
	var distanciaContinuarActivity;
	
	var acumulador;
	var contadorMuestras;
	var media;
	
	
	
	var mensajeTest;
	
	 function initialize() {
	 
	 	
    	app = App.getApp();
    	resetVariablesParent();
    	resetVariables();
        View.initialize();
    }
    
	function resetVariables(){
		
		genero=1.0d;
		edad=24.0d;
		peso=73.0d;
		heartRate=0.0d;
		
		testEnEjecucion=false;
		testDetenido=false;
		tiempoInicioTest=0.0d;
		tiempoTestDetenido=0.0d;
		tiempoTestReanudado=0.0d;
		tiempoDuracionTest=1; //llamar timer cada segundo para comprobar la distancia
		
		//media=0.0d;
		acumulador=0.0d;
		contadorMuestras=0.0d;
		
		

		//distancia al comienzo del test para no tenerla en cuenta
		distanciaInicioActivity=0.0d;
		distanciaDetenerActivity=0.0d;
		distanciaContinuarActivity=0.0d;
		//1 milla = 1.60934 km = 1609.34 m
		//distanciaRecorrer=1609.34d;
		distanciaRecorrer=20.34d;
		
		
	}
	
    //! Load your resources here
    function onLayout(dc) {
        setLayout(Rez.Layouts.Vo2maxSpeedLayout(dc));	
    }

    //! Update the view
    function onUpdate(dc) {
        // Call the parent onUpdate function to redraw the layout
		View.onUpdate( dc );	
		pintarVista(dc);
    }
    
    function pintarVista(dc){
    	var numFont = 6; 	
    	var msgFontMedium = 3;	// Gfx.FONT_MEDIUM
		var msgFontSmall = 2;	// Gfx.FONT_MEDIUM
		var just = 5;		// Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER
    	
    	var	X1 = 160;
		var	X2 = 60;
    	var Y1 = 43;
		var	Y2 = 127;
		  	
    	
    	if(media!=null && !testEnEjecucion){
    		dc.setColor(GREEN, -1);
    		dc.drawText(X2, Y1, numFont, media.format("%.2f"), just);
    	}else{
    		dc.setColor(RED, -1);
    		dc.drawText(X2, Y1, msgFontSmall, Ui.loadResource(Rez.Strings.esperando) , just);
    	}
    	
    	dc.setColor(WHITE, -1);
    	if(testEnEjecucion || !primeraMuestra){
			dc.drawText(X1, Y1, numFont, app.heartRate.toString(), just);
			dc.drawText(X1, Y2, numFont, app.speed.format("%.2f") , just);
		}else{
			dc.drawText(X1, Y1, numFont, "000", just);
			dc.drawText(X1, Y2, numFont, "00.00" , just);
		}
		

		dc.drawText(X2, Y2, numFont, timerPantalla(), just);
		
		dc.setColor(WHITE, -1);
    	if(testEnEjecucion==true){
			dc.drawText(105, 74, msgFontSmall, mensajeTest, just);
		}else{
			dc.drawText(105, 74, msgFontMedium, mensajeTest, just);
		}
		
    }

    
    function empezarTest(){
    	testEnEjecucion=true;
    	
 		Snsr.setEnabledSensors( [Snsr.SENSOR_HEARTRATE] );
		Snsr.enableSensorEvents( method(:onSnsr) );	
		//Snsr.setEnabledSensors();
				
    	mensajeTest = Ui.loadResource(Rez.Strings.mensajeTest2);
    	 	
    	tiempoInicioTest=Time.now().value();
    	timerTest= new Timer.Timer();
    	timerTest.start(method(:timerCallback),tiempoDuracionTest*1000,false);
    	
    	//asegurar que no cuenta distancias anteriores
		//parece que no deja modificar el activity directamente mal asunto

		var options = { :name => "OneMileWalkTest"  };
		activityrec=ActivityRecording.createSession(options);
		activityrec.start();
		distanciaInicioActivity=Activity.getActivityInfo().elapsedDistance;
		
    	System.println("Empezando test onemilewalk");
    }
    
    //no hace bien la detencion cuando esta en modo de estiamcion continua
    function detenerTest(){
    	testDetenido=true;
    	timerTest.stop();
    	tiempoTestDetenido=Time.now().value();
    	mensajeTest = Ui.loadResource(Rez.Strings.mensajeTest3);
    	distanciaDetenerActivity=Activity.getActivityInfo().elapsedDistance;
		if(activityrec.isRecording()){
			activityrec.stop();
		}
    	System.println("Detener test");
    }
    
    function continuarTest(){
    	testDetenido=false;
    	tiempoTestReanudado=Time.now().value();
    	
    	timerTest.start(method(:timerCallback),tiempoDuracionTest*1000,false);
    	
    	mensajeTest = Ui.loadResource(Rez.Strings.mensajeTest2);
    	activityrec.start();
    	distanciaContinuarActivity=Activity.getActivityInfo().elapsedDistance;

    	System.println("Continuar test");
    }
    
    function timerCallback(){	
    	
    	if(distanciaRecorrer<= distanciaRecorridaTest()){    			
	    	
	    	System.println("Peso "+peso);
			System.println("Edad "+edad);
			System.println("Genero "+genero);
			System.println("tiempoTestEnCurso "+tiempoTestEnCurso());
			System.println("Current hr "+app.heartRate);
	    	
	    	var aux =	 132.853 - 0.0769*peso - 0.3877*edad + 6.315*genero - 3.2649*tiempoTestEnCurso() - 0.1565*heartRate;           	
			System.println("estimacion onemilewalktest "+ aux);
	
			primeraMuestra=false;
			activityrec.stop();
			activityrec.save();
			resetVariables();
			media=aux;
		}else{
			var aux= distanciaRecorrer-distanciaRecorridaTest();
			System.println("Falta " + aux  + " por recorrer, distancia recorrida " + distanciaRecorridaTest());
			timerTest.start(method(:timerCallback),tiempoDuracionTest*1000,false);
		}
		
	    Ui.requestUpdate();
    }
    
    function distanciaRecorridaTest(){
    	//parecido al calculo del tiempo con el timer en vo2maxspeed
    	var result = 0.0d;
    	result=Activity.getActivityInfo().elapsedDistance;
    	return result - (distanciaInicioActivity +(distanciaContinuarActivity-distanciaDetenerActivity));   	
    }
     
    function finalizarTest(){
    	resetVariables();
    	System.println("Finalizar test");
    }
    
    function onSnsr(sensor_info){
    	if(sensor_info.heartRate!=null){
    		app.heartRate=sensor_info.heartRate;
    	}
    	
    	if(sensor_info.speed!=null){
    		app.speed=sensor_info.speed;
    	}
    	
    	Ui.requestUpdate();
    	return true; 
    }  
}




