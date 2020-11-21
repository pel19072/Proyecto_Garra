
import serial
import time
import sys
import math

#COMUNICACION SERIAL DE PIC CON LA CUMPU

# escritura
def escritura(puerto):
    final = []
    final1 = ''
    n = ''
    #borrar el buffer para iniciar en cero
    puerto.flushInput()
    puerto.flushOutput()
    try:
        puerto.readline()
        for i in range(1):
            recibido = str(puerto.readline()).split(',')
            final = recibido

        final[0] = 5*int(final[0][2:], 16)//13
        final[1] = 5*int(final[1][:2], 16)//13
        return final
    except:
        pass
    # RECUERDEN CONECTAR EL RX del pic AL TX de la compu

def lectura(puerto, x, y): #'99'
    puerto.flushOutput()
    # COORDENADA EN X
    try: #Este try sirve para ajustar los números que solo tienen un dígito
        anexo = x[1]
        puerto.write(bytes.fromhex(hex(ord(x[0]))[2:]))
        puerto.write(bytes.fromhex(hex(ord(x[1]))[2:]))
    except:
        puerto.write(bytes.fromhex(hex(ord('0'))[2:]))
        puerto.write(bytes.fromhex(hex(ord(x[0]))[2:]))
    #COMA
    puerto.write(bytes.fromhex('2C'))
    #COORDENADA EN Y
    try: #Este try sirve para ajustar los números que solo tienen un dígito
        anexo = y[1]
        puerto.write(bytes.fromhex(hex(ord(y[1]))[2:]))
        puerto.write(bytes.fromhex(hex(ord(y[0]))[2:]))
    except:
        puerto.write(bytes.fromhex(hex(ord(y[0]))[2:]))
        puerto.write(bytes.fromhex(hex(ord('0'))[2:]))
    #ENTER
    puerto.write(bytes.fromhex('0A'))
    return
