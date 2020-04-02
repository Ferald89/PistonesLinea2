'This is an example Home Routine
'The motor moves toward the home switch at SearchSpeed in the CW direction until Input 7 goes Low.  
'The motor stops then moves in the CCW direction at BackSpeed (slower speed) until Input 7 goes High.
'The motor stops and position is latched when Input 7 goes High.  This latched position is defined as the home position.
'The motor then does a move back to this home position.
'Cambio de armando
'pruebaramaarmando
'-------------- Device Params -----------------------
Params 
	DRV.OPMODE = 2		'position operation mode
	DRV.CMDSOURCE = 5	'command source = AKD BASIC TG
	UNIT.PROTARY = 3	'set position units to counts, 16 bit (65536counts/rev)
	UNIT.VROTARY = 0	'set velocity units to RPM
	UNIT.ACCROTARY = 0	'set acceleration units to rpm/s
End Params

'-------------- Define (dim) Global Variables --------
'dim SearchSpeed, BackSpeed as float 
'dim SearchDir as integer 
dim disab as integer
const ACC_Home = 3600
const Vel_Home = 100
const Home_Dir = 0
const Sw_Dir = 1
const ACC_Movs = 2500
const Vel_Movs = 2000
'-------------- Main Program -------------------------
Main 
	CAP0.EN = 0		    
	CAP0.EDGE = 1
	CAP0.EVENT = 0
	CAP0.FILTER = 0
	CAP0.MODE = 0
	CAP0.PREEDGE = 1
	CAP0.PREFILTER = 0
	CAP0.PRESELECT = 0
	CAP0.TRIGGER = 10
    	
	INTR.DISABLE = 1        'Activar interrupcion por drive desabilitado
	INTR.DIN1HI = 1		    'Interrumpir micro
	INTR.DIN2hi = 1		    'Interrumpir request home
    Intr.DIN21Hi = 1	    'Interrumpir start A1
	Intr.DIN22Hi = 1	    'Interrumpir start B1 
	Intr.DIN23Hi = 1	    'Interrumpir start A2
	Intr.DIN24Hi = 1	    'Interrumpir start B2
    Intr.DIN25Hi = 1		'Interrumpir start A3
	Intr.DIN26Hi = 1	    'Interrumpir start B3

	DOUT25.STATEU = 0       'Apagar senal de en home
    DOUT2.STATEU = 0        'Apagar senal de DESC1
    DOUT1.STATEU = 0        'Apagar senal de DESC2
    DOUT21.STATEU = 0       'Apagar senal de DESC3
	DOUT26.STATEU = 0       'Apagar senal de TERM1
	DOUT27.STATEU = 0       'Apagar senal de TERM2
	DOUT28.STATEU = 0       'Apagar senal de TERM3
    DOUT24.STATEU = 0       'Apagar seal de T.VERDE

    DOUT23.STATEU = 0       'Apagar en posicion
    DOUT2.STATEU = 0        'Apagar senal de DESC1
    DOUT1.STATEU = 0        'Apagar senal de DESC2
    DOUT21.STATEU = 0       'Apagar senal de DESC3
	
	cls 
	If Drv.active = 0 then print "Drive Desabilitado" 
	while Drv.Active = 0 : wend
	cls

	while (1) : 
        Call CanDes	            				'Llamar Candado Deshabilitado
		DOUT22.STATEU = 1	    				'T.Naranja (ESperando seales...)
        INTR.DISABLE = 1            			'Activar interrupcion por drive desabilitado
        disab = 0
	wend
End Main

'-------------- Subroutines and Functions ------------
Sub Go_Home
	Print "Ejecutando Home"
	Print "Subiendo piston"
	DOUT29.STATEU = 0						'Subir piston
	Print "Piston regreso"
    DOUT23.STATEU = 0                       'Desactivar en posicion
	Print "En posicion desactivado"
    DOUT2.STATEU = 0						'Apagar en posicion DESC1
	Print "En posicion DESC1 desactivado"
    DOUT1.STATEU = 0						'Apagar en posicion DESC2
	Print "En posicion DESC2 desactivado"
    DOUT21.STATEU = 0 						'Apagar en posicion DESC3
	Print "En posicion DESC3 desactivado"
    If DIN1.State = 1 then Call Cercasw     'Si micro ON, llamar subrutina Cercasw
	MOVE.ACC = ACC_Home						'Aceleracion en home
	MOVE.DEC = ACC_Home						'Desaceleracion en home
	MOVE.RUNSPEED = Vel_Home				'Velocidad en home
	MOVE.DIR = Home_Dir						'Direccion de giro del motor
	Pause(0.1)
	MOVE.GOVEL								'Mueve el motor a la velocidad y direccion especificados en RUNSPEED Y DIR
	move.runspeed = 0
	when DIN1.State = 1, move.goupdate 		'Cuando micro ON, se activa go.update
	while move.inposition = 0 : wend		'Espera a que se detenga el carro (repite la subrutina hasta que inposition=1
	
	MOVE.RUNSPEED = Vel_Home
	CAP0.EN = 1								'Inicia captura0
	MOVE.RELATIVEDIST = 10					'Moverse una distancia relativa de 10
	MOVE.GOREL								'Iniciar movimiento relativo
	while move.inposition = 0 : wend		'Espera a que se llegue a posicion
	Print "PL.FB = " , Pl.fb 				'Returns the position feedback value
	Print "CAP0.PLFB = " , CAP0.PLFB		'Reads capture position value
	Move.PosCommand = Pl.fb -CAP0.PLFB 
	Print "PL.FB = " , Pl.fb 
	MOVE.GOHOME								'Causes the motor to move to the position specified where PL.FB = 0. 
	while move.inposition = 0 : wend		'Espera a que se detenga.
        DOUT25.STATEU = 1
	Print "HOME TERMINADO"
End Sub
'--------------------------Rutina Fin 1---------------------------------------------------
Sub Term1 
    DOUT24.STATEU = 0                        	'Apagar Moviendo (Apagar T.Verde)
	print "Fin movimiento grado 1"
    DOUT23.STATEU = 1							'Activar en posicion
	print "En posicion de descarga grado 1"
	print "Esperando boton"
	When DIN7.State = 1,DOUT29.STATEU = 1		'Cuando detecta boton presionado, activa válvula de piston para retraerlo 
    When DIN30.State = 1 AND DIN31.State = 0, print "Piston bajo"
	print "Esperando boton por segunda vez"
    WHEN DIN7.State = 0, DOUT29.STATEU = 0  	'Esperar que salga pieza y levantar piston
    When DIN30.State = 0 AND DIN31.State = 1, print "Piston subio"
	Print "Liberacion grado 1 completa"
    DOUT26.STATEU = 1                       	'Activar termino  de secuencia 1, pulso 2 seg
    Pause(2.0)
    DOUT26.STATEU = 0
    Print "Termino Secuencia 1"
    DOUT23.STATEU = 0                        	'Desactivar en posicion
	Print "En posicion apagado"
End Sub 
'--------------------------Rutina Fin 2---------------------------------------------------
Sub Term2 
    DOUT24.STATEU = 0                        	'Apagar Moviendo (Apagar T.Verde)
	print "Fin movimiento grado 2"
	DOUT23.STATEU = 1 			 				'Activar en posicion
	print "En posicion de descarga grado 2"
	print "Esperando boton"              
	When DIN4.State = 1,DOUT29.STATEU = 1		'Cuando detecta boton presionado, activa válvula de piston para retraerlo 
    When DIN30.State = 1 AND DIN31.State = 0, print "Piston bajo"
	print "Esperando boton por segunda vez"
    WHEN DIN4.State = 0, DOUT29.STATEU = 0   	'Esperar que salga pieza y levantar piston
    When DIN30.State = 0 AND DIN31.State = 1, print "Piston subio"
	Print "Liberacion grado 2 completa"
    DOUT27.STATEU = 1                        	'Activar Termino  De Secuencia 2, pulso 2 seg
    Pause(2.0)
    DOUT27.STATEU = 0
    Print "Termino Secuencia 2"
    DOUT23.STATEU = 0                        	'Desactivar en posicin 
	Print "En posicion apagado"
End Sub 

'--------------------------Rutina Fin 3---------------------------------------------------
Sub Term3
    DOUT24.STATEU = 0                        	'Apagar Moviendo (Apagar T.Verde)
	print "Fin movimiento grado 3"
	DOUT23.STATEU = 1                        	'Activar en posicion
	print "En posicion de descarga grado 3"
	print "Esperando boton"
	When DIN3.State = 1,DOUT29.STATEU = 1    	'Cuando detecta boton presionado, activa válvula de piston para retraerlo 
    When DIN30.State = 1 AND DIN31.State = 0, print "Piston bajo"
	print "Esperando boton por segunda vez"
    WHEN DIN3.State = 0, DOUT29.STATEU = 0  	'Esperar que salga pieza y levantar piston
    When DIN30.State = 0 AND DIN31.State = 1, print "Piston subio"
	Print "Liberacion grado 3 completa"
    DOUT28.STATEU = 1                       	'Activar Termino  De Secuencia 3, pulso 2 seg
    Pause(2.0)
    DOUT28.STATEU = 0
    Print "Termino Secuencia 3"
    DOUT23.STATEU = 0                        	'Desactivar en posicion
	print "En posicion apagado"
End Sub 
 '--------------Rutina Candado 1a-------21--------
Sub Cand1a
        
	Intr.DIN22Hi = 0			'Interrumpir ir a B1
	Intr.DIN23Hi = 0			'Interrumpir ir a A2
	Intr.DIN24Hi = 0			'Interrumpir ir a B2
    Intr.DIN25Hi = 0			'Interrumpir ir a A3
	Intr.DIN26Hi = 0  			'Interrumpir ir a B3
End Sub    
 
'--------------Rutina Candado 1b--------22-------
Sub Cand1b
        
	Intr.DIN21Hi = 0			'Interrumpir ir a A1
	Intr.DIN23Hi = 0			'Interrumpir ir a A2
	Intr.DIN24Hi = 0			'Interrumpir ir a B2
    Intr.DIN25Hi = 0			'Interrumpir ir a A3
	Intr.DIN26Hi = 0			'Interrumpir ir a B3
End Sub  
'--------------Rutina Candado 2a--------23-------
Sub Cand2a
        
	Intr.DIN21Hi = 0			'Interrumpir ir a A1
	Intr.DIN22Hi = 0			'Interrumpir ir a B1
	Intr.DIN24Hi = 0			'Interrumpir ir a B2
    Intr.DIN25Hi = 0			'Interrumpir ir a A3
	Intr.DIN26Hi = 0			'Interrumpir ir a B3
End Sub  
'--------------Rutina Candado 2b--------24-------
Sub Cand2b
        
	Intr.DIN21Hi = 0			'Interrumpir ir a A1
	Intr.DIN22Hi = 0			'Interrumpir ir a B1
	Intr.DIN23Hi = 0			'Interrumpir ir a A2
    Intr.DIN25Hi = 0			'Interrumpir ir a A3
	Intr.DIN26Hi = 0			'Interrumpir ir a B3
End Sub  

'--------------Rutina Candado 3a--------25-------
Sub Cand3a
        
	Intr.DIN21Hi = 0			'Interrumpir ir a A1
	Intr.DIN22Hi = 0			'Interrumpir ir a B1
	Intr.DIN23Hi = 0			'Interrumpir ir a A2
    Intr.DIN24Hi = 0			'Interrumpir ir a B2
	Intr.DIN26Hi = 0			'Interrumpir ir a B3
End Sub  
'--------------Rutina Candado 3b---------26------
Sub Cand3b
        
	Intr.DIN21Hi = 0			'Interrumpir ir a A1
	Intr.DIN22Hi = 0			'Interrumpir ir a B1
	Intr.DIN23Hi = 0			'Interrumpir ir a A2
    Intr.DIN24Hi = 0			'Interrumpir ir a B2
	Intr.DIN25Hi = 0			'Interrumpir ir a A3
End Sub  
 
'--------------Quitar Candado---------------
Sub CanDes
        
	Intr.DIN21Hi = 1			'Quitar interrupcin de ir a A1
	Intr.DIN22Hi = 1			'Quitar interrupcin de ir a B1
	Intr.DIN23Hi = 1			'Quitar interrupcin de ir a A2
    Intr.DIN24Hi = 1			'Quitar interrupcin de ir a B2
	Intr.DIN25Hi = 1			'Quitar interrupcin de ir a A3
    Intr.DIN26Hi = 1			'Quitar interrupcin de ir a B3
End Sub  
'------------RUTINA EN MEDIO 1------------------------
Sub Desc1
       DOUT2.STATEU = 1                      'Activar salida DESC1
       print "En posicion DESC1", PL.FB
       DOUT24.STATEU = 0                     'Desactivar moviendo (Apagar T. Verde)
       print "Fin movimiento hacia riel grado 1"
       print "Esperando ingreso de charola en el carro" 
       When DIN27.State = 1,DOUT2.STATEU = 0 'Esperar que entre charola y desactivar DESC1
       When DIN27.State = 1, print "Charola detectada en carro"
       Pause(2.0)
       DOUT24.STATEU = 1                     'Activar en movimiento (Encender T. Verde)
       print "En movimiento hacia descarga grado 1"
End Sub

'------------RUTINA EN MEDIO 2------------------------
Sub Desc2
       DOUT1.STATEU = 1                      'Activar salida DESC2
       print "En posicion DESC2", PL.FB
       DOUT24.STATEU = 0                     'Desactivar moviendo (Apagar T. Verde)
       print "Fin movimiento hacia If DIN27.State = 0 then Call Riel1riel grado 2"
       print "Esperando ingreso de charola en el carro" 
       When DIN27.State = 1,DOUT1.STATEU = 0 'Esperar que entre charola y desactivar DESC2
       When DIN27.State = 1, print "Charola detectada en carro"
       Pause(2.0)
       DOUT24.STATEU = 1                     'Activar en movimiento (Encender T. Verde)
       print "En movimiento hacia descarga grado 2"
End Sub
'------------RUTINA EN MEDIO 3------------------------
Sub Desc3
       DOUT21.STATEU = 1                     'Activar salida DESC3
       print "En posicion DESC3", PL.FB
       DOUT24.STATEU = 0                     'Desactivar moviendo (Apagar T. Verde)
       print "Fin movimiento hacia riel grado 3"
       print "Esperando ingreso de charola en el carro" 
       When DIN27.State = 1,DOUT2.STATEU = 0 'Esperar que entre charola y desactivar DESC3
       When DIN27.State = 1, print "Charola detectada en carro"
       Pause(2.0)
       DOUT24.STATEU = 1                     'Activar en movimiento (Encender T. Verde)
       print "En movimiento hacia descarga grado 3"
End Sub
 '-------------- Rutina Grado 1 -------------------      
Sub Riel1
       cls
       DOUT22.STATEU = 0						'Apagar T. Naranja (Apagar en espera)
       Print "Ir a grado1"
       MOVE.ACC = ACC_Movs
       MOVE.DEC = ACC_Movs
       MOVE.RUNSPEED = Vel_Movs
       MOVE.TARGETPOS = -521				'Ir a posicion indicada
       MOVE.GOABS							'Iniciar movimiento absoluto
       DOUT24.STATEU = 1					'Activar en movimiento (Encender T. Verde)
       print "En movimiento hacia riel grado 1"
       while NOT(PL.FB =-521) AND (disab=0) :wend	
       print "Posición: ", PL.FB
       If disab =0 then Call Desc1			'Si drive deshabilitado, llamar a Desc1
 End Sub
 '-------------- Rutina Grado 2 -------------------      
Sub Riel2
       cls
       DOUT22.STATEU = 0					'Apagar T. Naranja (Apagar en espera)
       Print "Ir a grado2"
       MOVE.ACC = ACC_Movs
       MOVE.DEC = ACC_Movs
       MOVE.RUNSPEED = Vel_Movs
       MOVE.TARGETPOS = -880				'Ir a posicion indicada
       MOVE.GOABS							'Iniciar movimiento absoluto
       DOUT24.STATEU = 1					'Activar en movimiento (Encender T. Verde)
       print "En movimiento hacia riel grado 2"
       while NOT(PL.FB =-880) AND (disab=0) :wend
       print "Posición: ", PL.FB
       If disab =0 then Call Desc2			'Si drive deshabilitado, llamar a Desc2
End Sub
'-------------- Rutina Grado 3 -------------------      
Sub Riel3
       cls
       DOUT22.STATEU = 0					'Apagar T. Naranja (Apagar en espera)
       Print "Ir a grado3"
       MOVE.ACC = ACC_Movs
       MOVE.DEC = ACC_Movs
       MOVE.RUNSPEED = Vel_Movs
       MOVE.TARGETPOS = -1250				'Ir a posicion indicada
       MOVE.GOABS							'Iniciar movimiento absoluto
	   DOUT24.STATEU = 1					'Activar en movimiento (Encender T. Verde)
	   Print "En movimiento hacia riel grado 3"
	   While NOT (PL.FB = -1250) AND (disab=0) :Wend
       print "Posición: ", PL.FB
	   If disab =0 Then Call Desc3			'Si drive deshabilitado, llamar a Desc3
End Sub
'-------------- Rutina revisar sw -------------------      
Sub Cercasw
    Print "Moviendo para perdida de sw"
    MOVE.ACC = ACC_Home						'Aceleracion en home
	MOVE.DEC = ACC_Home						'Desaceleracion en home
	MOVE.RUNSPEED = Vel_Home				'Velocidad en home
	MOVE.DIR = Sw_Dir						'Direccion de giro del motor
	Pause(0.1)
	MOVE.GOVEL								'Mueve el motor a la velocidad y direccion especificados en RUNSPEED Y DIR
	move.runspeed = 0
	when DIN1.State = 0, move.goupdate 		'Espera la senal del micro, cuando lo detecta se activa move.goupdate
    when DIN1.State = 0, print "Se dejo de detectar micro"
	while move.inposition = 0 : wend		'Espera a que se detenga el carro (repite la subrutina hasta que inposition=1
	
	MOVE.RUNSPEED = Vel_Home
	CAP0.EN = 1								'Inicia captura0
	MOVE.RELATIVEDIST = -10					'Moverse una distancia relativa de 10
	MOVE.GOREL								'Iniciar movimiento relativo
	while move.inposition = 0 : wend		'Espera a que se llegue a posicion
End Sub


'---------------------------------------------------------------------- Interrupt Routines ------------------------------------------------------------------------------------

'--------------Interrupcion Drive deshabilitado--------
Interrupt DISABLE
    disab =3 
	cls
    Print "Drive Deshabilitado"
End Interrupt 
'--------------------------------------------------------    
Interrupt DIN1HI
	DRV.EN						'Habilita el Drive
	print "Drive habilitado"
	INTR.DIN1HI = 1				'Vuelve a activar la interrupcion ya que al entrar se desactiva para evitar se vuelta a disparar mientas esta ejecutando.
End Interrupt

Interrupt DIN2HI
	Call Go_Home				'Activa rutina de home
    INTR.DIN2HI = 1
End Interrupt
'-------------- 1A -------------------
Interrupt DIN21Hi
    Print "ACTIVO GRADO 1A"
    Call Cand1a 							'Llamar al candado 1A
    If DIN27.State = 0 then Call Riel1      'Si no hay charola, ir a cargar
    DOUT22.STATEU = 0						'Apagar T. Naranja
	MOVE.ACC = ACC_Movs
	DOUT2.STATEU = 0                        'Apagar en posicion Desc1
	print "En pos DESC1 apagado"
    MOVE.DEC = ACC_Movs
    MOVE.RUNSPEED = Vel_Movs
	MOVE.TARGETPOS = 73 					'Ir a posicion A1 
	MOVE.GOABS
    DOUT24.STATEU = 1						'Encender en movimiento (Encender T. Verde)
	print "En movimiento hacia A1"
    while NOT(PL.FB =73) AND (disab=0) :wend
    If disab =0 then Call Term1				'Si no esta el drive deshabilitado, llamar a Term1
    INTR.DIN21HI = 1 
End Interrupt

'-------------- 1B -------------------
Interrupt DIN22Hi
    Print "ACTIVO GRADO 1B"
    Call Cand1b								'Llamar al candado 1B
    If DIN27.State = 0 then Call Riel1      'Si no hay Charola, ir a cargar 
    DOUT22.STATEU = 0						'Apagar T. Naranja
	MOVE.ACC = ACC_Movs
    DOUT2.STATEU = 0                        'Apagar en posicion Desc1
	print "En pos DESC1 apagado"
    MOVE.DEC = ACC_Movs
    MOVE.RUNSPEED = Vel_Movs
	MOVE.TARGETPOS = -298					'Ir a posicion B1 
	MOVE.GOABS
    DOUT24.STATEU = 1						'Encender en movimiento (Encender T. Verde)
	print "En movimiento hacia B1"
	while NOT(PL.FB =-298) AND (disab=0) :wend
    If disab =0 then Call Term1				'Si no esta el drive deshabilitado, llamar a Term1
    INTR.DIN22HI = 1
End Interrupt
'-------------- 2A -------------------
Interrupt DIN23Hi
    Print "ACTIVO GRADO A2"
    Call Cand2a								'Llamar al candado 2A
    If DIN27.State = 0 then Call Riel2      'Si no hay charola, ir a cargar
    DOUT22.STATEU = 0						'Apagar T. Naranja
	MOVE.ACC = ACC_Movs
    DOUT1.STATEU = 0                        'Apagar en posicion Desc2
	print "En pos DESC2 apagado"
    MOVE.DEC = ACC_Movs
    MOVE.RUNSPEED = Vel_Movs
	MOVE.TARGETPOS = -1085 					'Ir a posicion A2 
	MOVE.GOABS
    DOUT24.STATEU = 1						'Encender en movimiento (Encender T. Verde)
	print "En movimiento hacia A2"
	while NOT(PL.FB =-1085) AND (disab=0) :wend
    If disab =0 then Call Term2				'Si no esta el drive deshabilitado, llamar a Term2
    INTR.DIN23HI = 1
End Interrupt
'-------------- 2B -------------------
Interrupt DIN24Hi
    Print "ACTIVO GRADO B2"
    Call Cand2b								'Llamar al candado 2B
    If DIN27.State = 0 then Call Riel2      'Si no hay charola, ir a cargar
    DOUT22.STATEU = 0						'Apagar T. Naranja
	MOVE.ACC = ACC_Movs
    DOUT1.STATEU = 0                        'Apagar en posicion Desc2
	print "En pos DESC2 apagado"
    MOVE.DEC = ACC_Movs
    MOVE.RUNSPEED = Vel_Movs
	MOVE.TARGETPOS = -1466					'Ir a posicion B2  
	MOVE.GOABS
    DOUT24.STATEU = 1						'Encender en movimiento (Encender T. Verde)
	print "En movimiento hacia B2"
	while NOT(PL.FB =-1466) AND (disab=0) :wend
    If disab =0 then Call Term2				'Si no esta el drive deshabilitado, llamar a Term2
    INTR.DIN24HI = 1
End Interrupt
'-------------- 3A -------------------
Interrupt DIN25Hi 
    Print "ACTIVO GRADO A3"
    Call Cand3a								'Llamar al candado 3A
    If DIN27.State = 0 then Call Riel3      'Si no hay charola, ir a cargar
    DOUT22.STATEU = 0						'Apagar T. Naranja
	MOVE.ACC = ACC_Movs
    DOUT21.STATEU = 0                       'Apagar en posicion Desc3
	print "En pos DESC3 apagado"
    MOVE.DEC = ACC_Movs
    MOVE.RUNSPEED = Vel_Movs
	MOVE.TARGETPOS = -2250					'Ir a posicion A3  
	MOVE.GOABS
    DOUT24.STATEU = 1						'Encender en movimiento (Encender T. Verde)
	print "En movimiento hacia A3"
	while NOT(PL.FB =-2250) AND (disab=0) :wend
    If disab =0 then Call Term3				'Si no esta el drive deshabilitado, llamar a Term3
    INTR.DIN25HI = 1
End Interrupt
'-------------- 3B -------------------
Interrupt DIN26Hi
    Print "ACTIVO GRADO B3"
    Call Cand3b                             'Asegurar que no haya otra interrupcion de movimiento
    If DIN27.State = 0 then Call Riel3      'Si no hay charola, ir a cargar
    DOUT22.STATEU = 0						'Apagar T. Naranja
    MOVE.ACC = ACC_Movs
    DOUT21.STATEU = 0                       'Apagar en posicion Desc3
	print "En pos DESC3 apagado"
    MOVE.DEC = ACC_Movs
    MOVE.RUNSPEED = Vel_Movs
	MOVE.TARGETPOS = -2617					'Ir a posicion B3 
	MOVE.GOABS
    DOUT24.STATEU = 1						'Encender en movimiento (Encender T. Verde)
	print "En movimiento hacia B3"
	while NOT(PL.FB =-2617) AND (disab=0) :wend
    If disab =0 then Call Term3				'Si no esta el drive deshabilitado, llamar a Term3
    INTR.DIN26HI = 1
End Interrupt




















































