import numpy as np
import time
import pyvisa as visa

'''
Class to control the QDAC power supply.
'''

'''
To find IP address:
    -it should be fixed at 192.168.88.254, but if it changes follow steps below
    -connect by usb using direction on documentation
    -HTerm and YAT are both downloaded. HTerm usually works but for some reason it has issues sometimes, so use YAT
        -dont forget to set baudrate to 921600 and EOL sequence to LF
    -send SYST:COMM:LAN:IPAD?
    TCPIP0::192.168.88.254::5025::SOCKET
'''

class QDAC_II():
    def __init__(self, visa_addr="TCPIP::192.168.88.254::5025::SOCKET", lib=''):
        self.rm = visa.ResourceManager('@py') 
        self.instr = self.rm.open_resource(visa_addr)
        self.instr.write_termination = '\n'
        self.instr.read_termination = '\n'

    # send SCPI command and return response
    def query(self, cmd):
        return self.instr.query(cmd)
    
    # send SCPI command, no response
    def write(self, cmd):
        self.instr.write(cmd)
        
    # read SCPI response, mainly used for waiting
    def read(self):
        return self.instr.read()
    
    # if you want to send commands in binary instead of ascii for some reason
    def write_binary_values(self, cmd, values):
        self.instr.write_binary_values(cmd, values)
        
    # close visa session
    def close(self):
        self.rm.close()
        
    #sets specified channel to specified voltage (V)
    def setVoltage(self, channel, voltage):
        self.instr.write("SOURce"+ str(channel) + ":VOLT:MODE FIXed")
        self.instr.write("SOURce" + str(channel) + ":VOLT " + str(voltage))
    
    # sets slew rate and voltage for a given channel
    
    # slew rate min: 20, max: 2e7, in V/s    
    # numPoints min: 1, max: 65536
    # dwellTime min: 1e-6, max: 36000 (10hrs), in seconds
    def setVoltageSweep(self, channel, start, stop, slewRate, numPoints, dwellTime):
        #set to sweep mode
        self.instr.write("SOURce"+ str(channel) + ":VOLT:MODE SWEep")
        #set slew rate
        self.instr.write("SOURce"+ str(channel) + ":VOLT:SLEW " + str(slewRate))
        #set start and stop voltages
        self.instr.write("SOURce"+ str(channel) + ":SWEep:STARt " + str(start))
        self.instr.write("SOURce"+ str(channel) + ":SWEep:STOP " + str(stop))
        #set numPoints and dwellRate
        self.instr.write("SOURce"+ str(channel) + ":SWEep:POINts " + str(numPoints))
        self.instr.write("SOURce"+ str(channel) + ":SWEep:DWELl " + str(dwellTime))
        #start the sweep
        self.instr.write("SOURce"+ str(channel) + ":DC:INIT")
        
    # returns voltage in channel
    def getVoltage(self, channel):
        return(self.instr.query("SOURce"+ str(channel) + ":VOLT?"))
    
    # returns current in channel
    def getCurrent(self, channel):
        return(self.instr.query("READ" + str(channel) + "?"))
    
    # return errors
    def getErrors(self):
        return(self.instr.query("SYSTem:ERRor:ALL?"))

    def set_voltage(self, channel, voltage, dwell = 0.5):
        """Set QDAC target voltage using a VoltageSweep"""
        slewrate = 10 #V/s
        dwelltime = dwell #s
        numpointsqdac = 10
        if (voltage < 5) and (voltage > - 5):
            start_voltage = self.getVoltage(channel)
            stop_voltage = voltage
            self.setVoltageSweep(channel, start_voltage, stop_voltage, slewrate, numpointsqdac, dwelltime)
            while not np.isclose(float(self.getVoltage(channel)), float(stop_voltage), rtol=1e-05, atol=1e-08, equal_nan=False):
                time.sleep(0.1)
