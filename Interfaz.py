from Design_Union import *
from PyQt5 import QtWidgets
import threading
import serial
import time
import sys
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

    def actualizacion(self):
        self.update()

def controles():
    global ventanamain, toggle, garra, value_vertical, value_horizontal
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
            # Enter
            ser.write(bytes.fromhex('0A'))
            print(ser.read())
            ventanamain.actualizacion()
            #print('*****************************************COMPUTADORA*******************************************')
            #print('Toggle = ', toggle, ' y manda 39\nGarra = ', garra, '\nVertical = ', hex(ord(str(value_vertical)))[2:], '\nHorizontal = ', hex(ord(str(value_horizontal)))[2:])

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
                # Enter
                ser.write(bytes.fromhex('0A'))
                print(ser.read())
                ventanamain.actualizacion()
                #print('Toggle = ', toggle, ' y manda 30\nGarra = ', garra, '\nVertical = ', hex(ord(str(value_vertical)))[2:], '\nHorizontal = ', hex(ord(str(value_horizontal)))[2:])
            except:
                pass

aplication = QtWidgets.QApplication([])
ventanamain=SKETCH()
ventanamain.show()
aplication.exec_()
