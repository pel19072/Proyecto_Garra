from Design_Union import *
from PyQt5 import QtWidgets
import threading
import serial
import time
import sys
usuario = 0
toggle = 0
garra = 0
value_horizontal = 0
value_vertical = 0
class SKETCH (QtWidgets.QMainWindow, Ui_MainWindow):
    def __init__ (self):
        super().__init__()
        self.setupUi(self)
        self.pushButton.clicked.connect(self.presionado1)
        self.pushButton_2.clicked.connect(self.presionado2)
        self.pushButton_3.clicked.connect(self.cerrar)
        self.pushButton_4.clicked.connect(self.abrir)
        self.pushButton_5.clicked.connect(self.us1)
        self.pushButton_6.clicked.connect(self.us2)
        self.horizontalSlider.valueChanged.connect(self.obtener_valor_horizontal)
        self.verticalSlider.valueChanged.connect(self.obtener_valor_vertical)
        instruccion = threading.Thread(daemon=True,target=controles)
        instruccion.start()

    def presionado1(self):
        global toggle
        toggle = 0

    def presionado2(self):
        global toggle
        toggle = 1

    def abrir(self):
        global garra
        garra = 0

    def cerrar(self):
        global garra
        garra = 1

    def obtener_valor_horizontal(self):
        global value_horizontal
        value_horizontal = self.horizontalSlider.value()

    def obtener_valor_vertical(self):
        global value_vertical
        value_vertical = self.verticalSlider.value()

    def us1(self):
        global usuario
        usuario = 0

    def us2(self):
        global usuario
        usuario = 1

    def last(self, ultimo_usuario):
        self.label_7.setText("ÚLTIMO USUARIO ACTIVO:\n" + ultimo_usuario)

    def actualizacion(self):
        self.update()

def controles():
    global ventanamain, toggle, garra, value_vertical, value_horizontal, usuario
    ser = serial.Serial(port='COM4',baudrate=9600, parity=serial.PARITY_NONE, stopbits=serial.STOPBITS_ONE,bytesize=serial.EIGHTBITS, timeout=0)
    while (1) :
        ser.flushOutput()
        if (toggle == 1):
            # Mando 9 para control manual
            ser.write(bytes.fromhex('39'))
            print(ser.read())
            # Coma
            ser.write(bytes.fromhex('2C'))
            print(ser.read())
            # Posicion primer servo
            if (garra == 1):
                # 00 para posición mínima
                ser.write(bytes.fromhex('30'))
                print(ser.read())
            else:
                # 9 para posición máxima
                ser.write(bytes.fromhex('39'))
                print(ser.read())
            # Coma
            ser.write(bytes.fromhex('2C'))
            print(ser.read())
            # Posicion segundo servo
            ser.write(bytes.fromhex(hex(ord(str(value_vertical)))[2:]))
            print(ser.read())
            # Coma
            ser.write(bytes.fromhex('2C'))
            print(ser.read())
            # Posicion tercer servo
            ser.write(bytes.fromhex(hex(ord(str(value_horizontal)))[2:]))
            print(ser.read())
            # Coma
            ser.write(bytes.fromhex('2C'))
            print(ser.read())
            # Usuario actual
            ser.write(bytes.fromhex(hex(ord(str(usuario)))[2:]))
            print(ser.read())
            # Enter
            ser.write(bytes.fromhex('0A'))
            print(ser.read())
            #ser.flushInput()
            '''
            try:
                ser.readline()
                final = str(ser.readline()).split(',')
                final[0] = int(final[0][2:], 16)
                #final = ['hola']
                ventanamain.last(str(final[0]))
            except:
                pass
            '''
            ventanamain.actualizacion()

        else:
            try :
                # Mando 00 para control manual
                ser.write(bytes.fromhex('30'))
                print(ser.read())
                # Coma
                ser.write(bytes.fromhex('2C'))
                print(ser.read())
                # Posicion primer servo
                ser.write(bytes.fromhex('30'))
                print(ser.read())
                # Coma
                ser.write(bytes.fromhex('2C'))
                print(ser.read())
                # Posicion segundo servo
                ser.write(bytes.fromhex('30'))
                print(ser.read())
                # Coma
                ser.write(bytes.fromhex('2C'))
                print(ser.read())
                # Posicion tercer servo
                ser.write(bytes.fromhex('30'))
                print(ser.read())
                # Coma
                ser.write(bytes.fromhex('2C'))
                print(ser.read())
                # Usuario actual
                ser.write(bytes.fromhex(hex(ord(str(usuario)))[2:]))
                print(ser.read())
                # Enter
                ser.write(bytes.fromhex('0A'))
                print(ser.read())
                #ser.flushInput()
                '''
                try:
                    ser.readline()
                    recibido = str(ser.readline()).split(',')
                    final = recibido
                    final[0] = int(final[0][2:], 16)
                    #final = ['adios']
                    ventanamain.last(str(final[0]))
                except:
                    pass
                '''
                ventanamain.actualizacion()
            except:
                pass

aplication = QtWidgets.QApplication([])
ventanamain=SKETCH()
ventanamain.show()
aplication.exec_()
