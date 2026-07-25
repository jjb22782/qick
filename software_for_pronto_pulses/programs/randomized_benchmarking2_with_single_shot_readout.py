##################################
## RANDOMIZED BENCHMARKING CODE ##
##################################

from qick import *
from qick.helpers import gauss

import numpy as np

## FUNCTIONS FOR: CONSTRUCTING RANDOM CLIFFORD GATE SEQUENCES OF SIZE N AND COMPUTING THEIR INVERSE
class CliffordGates:
    #CLIFFORDGATES[ii][0] - THE CLIFFORD GATE'S NAME
    #CLIFFORDGATES[ii][1] - THE CLIFFORD GATE'S INVERSE'S NAME
    #CLIFFORDGATES[ii][2] - THE CLIFFORD GATE'S X INVERSE'S NAME
    #CLIFFORDGATES[ii][3] - THE CLIFFORD GATE'S DECOMPOSITION USING JUST: X/2=Rx(pi/2), Z/2=Rz(-pi/2)
    #CLIFFORDGATES[ii][4] - THE CLIFFORD GATE'S 3x3 MATRIX REPRESENTATION
    _CLIFFORDGATES = [
        ['I',   'I',    'X',    [                                               ],np.array([[ 1, 0, 0],[ 0, 1, 0],[ 0, 0, 1]])],
        ['X',   'X',    'I',    [                  'X/2','X/2',                 ],np.array([[ 1, 0, 0],[ 0,-1, 0],[ 0, 0,-1]])],
        ['Y',   'Y',    'Z',    ['Z/2','Z/2',      'X/2','X/2',                 ],np.array([[-1, 0, 0],[ 0, 1, 0],[ 0, 0,-1]])],
        ['Z',   'Z',    'Y',    ['Z/2','Z/2',                                   ],np.array([[-1, 0, 0],[ 0,-1, 0],[ 0, 0, 1]])],
        
        ['H',   'H',    'HZ',   ['Z/2','Z/2','Z/2','X/2',      'Z/2','Z/2','Z/2'],np.array([[ 0, 0, 1],[ 0,-1, 0],[ 1, 0, 0]])],
        ['HX',  'HZ',   'H',    ['Z/2','Z/2','Z/2','X/2',      'Z/2',           ],np.array([[ 0, 0,-1],[ 0, 1, 0],[ 1, 0, 0]])],
        ['HY',  'HY',   'HX',   ['Z/2',            'X/2',      'Z/2',           ],np.array([[ 0, 0,-1],[ 0,-1, 0],[-1, 0, 0]])],
        ['HZ',  'HX',   'HY',   ['Z/2',            'X/2',      'Z/2','Z/2','Z/2'],np.array([[ 0, 0, 1],[ 0, 1, 0],[-1, 0, 0]])],
        
        ['S',   'SZ',   'SX',   ['Z/2','Z/2','Z/2'                              ],np.array([[ 0,-1, 0],[ 1, 0, 0],[ 0, 0, 1]])],
        ['SX',  'SX',   'SZ',   ['Z/2',            'X/2','X/2',                 ],np.array([[ 0, 1, 0],[ 1, 0, 0],[ 0, 0,-1]])],
        ['SY',  'SY',   'S',    ['Z/2','Z/2','Z/2','X/2','X/2',                 ],np.array([[ 0,-1, 0],[-1, 0, 0],[ 0, 0,-1]])],
        ['SZ',  'S',    'SY',   ['Z/2',                                         ],np.array([[ 0, 1, 0],[-1, 0, 0],[ 0, 0, 1]])],
        
        ['HS',  'SHX',  'SHZ',  ['Z/2','Z/2',      'X/2',      'Z/2','Z/2','Z/2'],np.array([[ 0, 0, 1],[-1, 0, 0],[ 0,-1, 0]])],
        ['HSX', 'SHZ',  'SHX',  [                  'X/2',      'Z/2',           ],np.array([[ 0, 0,-1],[-1, 0, 0],[ 0, 1, 0]])],
        ['HSY', 'SHY',  'SH',   ['Z/2','Z/2',      'X/2',      'Z/2',           ],np.array([[ 0, 0,-1],[ 1, 0, 0],[ 0,-1, 0]])],
        ['HSZ', 'SH',   'SHY',  [                  'X/2',      'Z/2','Z/2','Z/2'],np.array([[ 0, 0, 1],[ 1, 0, 0],[ 0, 1, 0]])],
        
        ['HSH', 'HSHX', 'HSH',  [                  'X/2',                       ],np.array([[ 1, 0, 0],[ 0, 0,-1],[ 0, 1, 0]])],
        ['HSHX','HSH',  'HSHX', ['Z/2','Z/2',      'X/2',      'Z/2','Z/2',     ],np.array([[ 1, 0, 0],[ 0, 0, 1],[ 0,-1, 0]])],
        ['HSHY','HSHY', 'HSHZ', [                  'X/2',      'Z/2','Z/2',     ],np.array([[-1, 0, 0],[ 0, 0, 1],[ 0, 1, 0]])],
        ['HSHZ','HSHZ', 'HSHY', ['Z/2','Z/2',      'X/2',                       ],np.array([[-1, 0, 0],[ 0, 0,-1],[ 0,-1, 0]])],
        
        ['SH',  'HSZ',  'HS',   ['Z/2','Z/2','Z/2','X/2',      'Z/2','Z/2',     ],np.array([[ 0, 1, 0],[ 0, 0, 1],[ 1, 0, 0]])],
        ['SHX', 'HS',   'HSZ',  ['Z/2','Z/2','Z/2','X/2',                       ],np.array([[ 0,-1, 0],[ 0, 0,-1],[ 1, 0, 0]])],
        ['SHY', 'HSY',  'HSX',  ['Z/2',            'X/2',                       ],np.array([[ 0, 1, 0],[ 0, 0,-1],[-1, 0, 0]])],
        ['SHZ', 'HSX',  'HSY',  ['Z/2',            'X/2',      'Z/2','Z/2',     ],np.array([[ 0,-1, 0],[ 0, 0, 1],[-1, 0, 0]])]
    ]

    _getCliffordGateName                 = lambda cliffordgate : cliffordgate[0]
    _getCliffordGateInverseName          = lambda cliffordgate : cliffordgate[1]
    _getCliffordGateXInverseName         = lambda cliffordgate : cliffordgate[2]
    _getCliffordGateDecomposition        = lambda cliffordgate : cliffordgate[3]
    _getCliffordGateMatrixRepresentation = lambda cliffordgate : cliffordgate[4]

    def _getCliffordGateByName(name):
        for cliffordgate in CliffordGates._CLIFFORDGATES:
            if(name == CliffordGates._getCliffordGateName(cliffordgate)):
                return cliffordgate

    def _getCliffordGateByMatrixRepresentation(matrix):
        for cliffordgate in CliffordGates._CLIFFORDGATES:
            if(np.array_equal(matrix, CliffordGates._getCliffordGateMatrixRepresentation(cliffordgate))):
                return cliffordgate

    # INTENDED PUBLIC FUNCTIONS

    def getCliffordGateName(gate):
        return CliffordGates._getCliffordGateName(gate)

    def genRandomCliffordGates(N):
        return [CliffordGates._CLIFFORDGATES[randint] for randint in np.random.randint(len(CliffordGates._CLIFFORDGATES),size=N)]

    def getProductOfCliffordGates(gates):
        runningproduct = np.array([[1,0,0],[0,1,0],[0,0,1]])
        for gate in gates:
            runningproduct = np.matmul(CliffordGates._getCliffordGateMatrixRepresentation(gate), runningproduct)
        return CliffordGates._getCliffordGateByMatrixRepresentation(runningproduct)

    def getInverseCliffordGate(gate):
        return CliffordGates._getCliffordGateByName(CliffordGates._getCliffordGateInverseName(gate))

    def getXInverseCliffordGate(gate):
        return CliffordGates._getCliffordGateByName(CliffordGates._getCliffordGateXInverseName(gate))

    def getCliffordGateDecomposition(gate):
        return CliffordGates._getCliffordGateDecomposition(gate)
    
    def getXd2Gate():
        return CliffordGates._getCliffordGateByName('HSH')

## FUNCTIONS FOR GENERATING THE X/2 PULSE
class Xd2Gen:
    def _genSineWave(ts, freq):
        return np.sin(2*np.pi*freq*ts)

    def _genGaussianWindow(ts, sigma):
        b = (ts[-1]+ts[0])/2
        c = sigma
        f = [np.exp(-(t-b)**2/(2*c**2)) for t in ts]
        f = f - min(f)
        return f

    def _miscGenchirp(num_samples, sampling_interval, start_freq=100e6, end_freq=400e6):
        timefinal = sampling_interval*num_samples
        t         = np.arange(0, timefinal-sampling_interval, sampling_interval)
        waveform  = np.sin(2 * np.pi * (start_freq*((timefinal-t)/timefinal) + 4*end_freq*(t/timefinal)) * t)
        return waveform

    def _load_csv_waveform(filepath, maxv):
        """Generate a manual sinusoidal waveform for testing."""
        waveform = np.genfromtxt(filepath, delimiter=",")
        waveform *= maxv / np.max(np.abs(waveform))  # Scale waveform
        return waveform

    ## INTENDED PUBLIC FUNCTIONS

    def getGaussianSinusoidPulse(ts, freq, sigma, samps_per_clk=64):
        waveform = Xd2Gen._genSineWave(ts, freq)*Xd2Gen._genGaussianWindow(ts, sigma)
        waveform = np.pad(waveform, (0, (samps_per_clk - len(waveform) % samps_per_clk)%samps_per_clk))
        return waveform

    def getFakeXd2Pulse(ts, freq, sigma, samps_per_clk=64):
        waveform = Xd2Gen.getGaussianSinusoidPulse(ts, freq, sigma, samps_per_clk)
        if(samps_per_clk!=0):
                # Pad end of waveform with zeros to reach integer multiple of samps_per_clk:
                 np.pad(waveform, (0, (samps_per_clk - len(waveform) % samps_per_clk)%samps_per_clk))
        return waveform

    def getXd2Pulse(name="", amplitude=1., samps_per_clk=0):
        waveform = Xd2Gen._load_csv_waveform(name, amplitude)
        if(samps_per_clk!=0):
            # Pad end of waveform with zeros to reach integer multiple of samps_per_clk:
             np.pad(waveform, (0, (samps_per_clk - len(waveform) % samps_per_clk)%samps_per_clk))
        return waveform

## FUNCTIONS FOR: CREATING WAVEFORMS FROM X/2, Z/2 PULSES
class PulseGen:
    _workingpulsexd2starttimes = []
    _workingpulsecurrenttime   = 0.
    _workingpulsezphaseoffset  = 0
    _OPTIMALXd2PULSE           = []
    _OPTIMALXd2PULSEDURATION   = 0.
    _QUBITPERIOD               = 0.
    _DACOUTPUTCLOCKPERIOD      = 0.
    _DACSAMPLESPERINPUTCLOCK   = 0

    def _computeNextTime(currenttime, desiredphaseoffset, period):
        currenttimefractionalpart, currenttimeintegralpart = np.modf(currenttime/period)
        if(currenttimefractionalpart < desiredphaseoffset):
            additionalfractionaloffset = desiredphaseoffset-currenttimefractionalpart
        else:
            additionalfractionaloffset = desiredphaseoffset-currenttimefractionalpart+1.
        return (currenttime + additionalfractionaloffset*period)

    def _getval(pulse, index):
        if(index<0 or index>=len(pulse)):
            return 0.0
        else:
            return pulse[index]

    ## INTENDED PUBLIC FUNCTIONS

    def interpolate(pulse, pulseduration, ts):
        interpolatedwave = np.zeros(len(ts))
        for ii in range(len(ts)):
            index  = len(pulse)*(ts[ii]/pulseduration)
            ia     = np.floor(index).astype(int)
            ib     = np.ceil(index).astype(int)
            if(ia==ib):
                interpolatedwave[ii] = PulseGen._getval(pulse,ia)
            else:
                interpolatedwave[ii] = (ib-index)*PulseGen._getval(pulse,ia) + (index-ia)*PulseGen._getval(pulse,ib)
        return interpolatedwave

    def genArbitraryPulseStart(OPTIMALXd2PULSE, OPTIMALXd2PULSEDURATION, QUBITPERIOD, DACOUTPUTCLOCKPERIOD, DACSAMPLESPERINPUTCLOCK=64):
        PulseGen._workingpulsexd2starttimes = []
        PulseGen._workingpulsecurrenttime   = 0.
        PulseGen._workingpulsezphaseoffset  = 0.
        PulseGen._OPTIMALXd2PULSE           = OPTIMALXd2PULSE
        PulseGen._OPTIMALXd2PULSEDURATION   = OPTIMALXd2PULSEDURATION
        PulseGen._QUBITPERIOD               = QUBITPERIOD
        PulseGen._DACOUTPUTCLOCKPERIOD      = DACOUTPUTCLOCKPERIOD
        PulseGen._DACSAMPLESPERINPUTCLOCK   = DACSAMPLESPERINPUTCLOCK

    def genArbitraryPulseAddGate(gate):
        if(gate == 'Z/2'):
            PulseGen._workingpulsezphaseoffset = (PulseGen._workingpulsezphaseoffset + 1./4)%1.
        if(gate == 'X/2'):
            nextstarttime = PulseGen._computeNextTime(PulseGen._workingpulsecurrenttime, PulseGen._workingpulsezphaseoffset, PulseGen._QUBITPERIOD)
            PulseGen._workingpulsexd2starttimes.append(nextstarttime)
            PulseGen._workingpulsecurrenttime = nextstarttime + PulseGen._OPTIMALXd2PULSEDURATION

    def genArbitraryPulseAddGates(gates):
        for gate in gates:
            PulseGen.genArbitraryPulseAddGate(gate)

    def genArbitraryPulseGetOutput():
        if(len(PulseGen._workingpulsexd2starttimes)==0):
            return np.zeros(PulseGen._DACSAMPLESPERINPUTCLOCK), np.zeros(PulseGen._DACSAMPLESPERINPUTCLOCK)
        else:
            endtime                     = PulseGen._workingpulsexd2starttimes[-1] + PulseGen._OPTIMALXd2PULSEDURATION
            interpolatedwavenumsamples  = np.floor(endtime/PulseGen._DACOUTPUTCLOCKPERIOD).astype(int) + 1
            interpolatedwavenumsamples += (PulseGen._DACSAMPLESPERINPUTCLOCK - interpolatedwavenumsamples%PulseGen._DACSAMPLESPERINPUTCLOCK)
            #
            ts    = np.array([PulseGen._DACOUTPUTCLOCKPERIOD*ii for ii in range(interpolatedwavenumsamples)])
            pulse = np.zeros(interpolatedwavenumsamples)
            for workingpulsexd2starttime in PulseGen._workingpulsexd2starttimes:
                startii = max(np.floor(workingpulsexd2starttime/PulseGen._DACOUTPUTCLOCKPERIOD).astype(int)-1, 0)
                endii   = min(np.ceil((workingpulsexd2starttime+PulseGen._OPTIMALXd2PULSEDURATION)/PulseGen._DACOUTPUTCLOCKPERIOD).astype(int)+1, len(ts)-1)
                pulse[startii:endii+1] += PulseGen.interpolate(PulseGen._OPTIMALXd2PULSE, PulseGen._OPTIMALXd2PULSEDURATION, ts[startii:endii+1]-workingpulsexd2starttime)
            return ts, pulse

## CLASS FOR RUNNING RANDOMIZED BENCHMARKING ON THE QICK BOARD
class RandomizedBenchmarking2SingleShotReadoutProgram(AveragerProgram):
    def initialize(self):
        cfg = self.cfg
        self.declare_gen(ch=cfg["res_ch"], nqz=1)  # READOUT
        self.declare_gen(ch=cfg["qubit_ch"], nqz=2)  # QUBIT
        for ch in [0,1]:  # CONFIGURE THE READOUT LENGTHS AND DOWNCONVERSION FREQUENCIES
            self.declare_readout(
                ch     = ch,
                length = cfg["res_readout_length"],
                freq   = cfg["res_freq"],
                gen_ch = cfg["res_ch"],
            )
        self.q_rp   = self.ch_page(self.cfg["qubit_ch"])                          # GET REGISTER PAGE FOR QUBIT_CH
        self.r_freq = self.sreg(cfg["qubit_ch"], "freq")                          # GET FREQUENCY REGISTER FOR QUBIT_CH
        f_res       = self.freq2reg(cfg["res_freq"], gen_ch=cfg["res_ch"], ro_ch=0)  # CONVERT F_RES TO DAC REGISTER VALUE
        # ADD QUBIT PULSE
        self.add_pulse(
            ch    = cfg["qubit_ch"],
            name  = cfg["qubit_pulse_name"],
            idata = cfg["qubit_i_data"],
            qdata = cfg["qubit_q_data"],
        )
        # ADD QUBIT AND READOUT PULSES TO RESPECTIVE CHANNELS
        self.set_pulse_registers(
            ch       = cfg["qubit_ch"],
            style    = "arb",
            gain     = cfg["qubit_gain"],
            waveform = cfg["qubit_pulse_name"],
            outsel   = "input",
            freq     = 0, #ARTIFACT OF ADAPTING QICK SW
            phase    = 0, #ARTIFACT OF ADAPTING QICK SW
        )
        self.set_pulse_registers(
            ch     = cfg["res_ch"],
            style  = "const",
            freq   = f_res,
            phase  = self.deg2reg(cfg["res_phase"], gen_ch=cfg["res_ch"]),
            gain   = cfg["res_gain"],
            length = cfg["res_readout_length"],
        )
        self.sync_all(self.us2cycles(1))

    def body(self):
        # trigger measurement, play measurement pulse, wait for qubit to relax
        self.measure(
            pulse_ch=self.cfg["res_ch"],
            adcs=[0, 1],
            adc_trig_offset=self.cfg["adc_trig_offset"],
            wait=True,
            syncdelay=self.us2cycles(self.cfg["delta_t"]),
        )
        # play probe pulse
        self.pulse(ch=self.cfg["qubit_ch"])
        self.sync_all(self.us2cycles(0.001))# align channels
        # Measure again
        self.measure(
            pulse_ch=self.cfg["res_ch"],
            adcs=[0, 1],
            adc_trig_offset=self.cfg["adc_trig_offset"],
            wait=True,
            syncdelay=self.us2cycles(self.cfg["relax_delay"]),
        )

    def acquire(self, soc, load_pulses=True, progress=False):
        avg_di, avg_dq = super().acquire(soc, load_pulses=load_pulses, progress=progress)
        self.avg_di = avg_di
        self.avg_dq = avg_dq
        #
        shots_i0 = (
            self.di_buf[0].reshape((self.cfg["reps"], 2))
            / self.cfg["res_readout_length"]
        )
        shots_q0 = (
            self.dq_buf[0].reshape((self.cfg["reps"], 2))
            / self.cfg["res_readout_length"]
        )
        #
        return shots_i0, shots_q0

## CLASS FOR RUNNING RANDOMIZED BENCHMARKING ON THE QICK BOARD
class RandomizedBenchmarking2OriginalProgram(AveragerProgram):
    def initialize(self):
        cfg = self.cfg
        self.declare_gen(ch=cfg["res_ch"], nqz=1)  # READOUT
        self.declare_gen(ch=cfg["qubit_ch"], nqz=2)  # QUBIT
        for ch in [0,1]:  # CONFIGURE THE READOUT LENGTHS AND DOWNCONVERSION FREQUENCIES
            self.declare_readout(
                ch     = ch,
                length = cfg["res_readout_length"],
                freq   = cfg["res_freq"],
                gen_ch = cfg["res_ch"],
            )
        self.q_rp   = self.ch_page(self.cfg["qubit_ch"])                          # GET REGISTER PAGE FOR QUBIT_CH
        self.r_freq = self.sreg(cfg["qubit_ch"], "freq")                          # GET FREQUENCY REGISTER FOR QUBIT_CH
        f_res       = self.freq2reg(cfg["res_freq"], gen_ch=cfg["res_ch"], ro_ch=0)  # CONVERT F_RES TO DAC REGISTER VALUE
        # ADD QUBIT PULSE
        self.add_pulse(
            ch    = cfg["qubit_ch"],
            name  = cfg["qubit_pulse_name"],
            idata = cfg["qubit_i_data"],
            qdata = cfg["qubit_q_data"],
        )
        # ADD QUBIT AND READOUT PULSES TO RESPECTIVE CHANNELS
        self.set_pulse_registers(
            ch       = cfg["qubit_ch"],
            style    = "arb",
            gain     = cfg["qubit_gain"],
            waveform = cfg["qubit_pulse_name"],
            outsel   = "input",
            freq     = 0, #ARTIFACT OF ADAPTING QICK SW
            phase    = 0, #ARTIFACT OF ADAPTING QICK SW
        )
        self.set_pulse_registers(
            ch     = cfg["res_ch"],
            style  = "const",
            freq   = f_res,
            phase  = self.deg2reg(cfg["res_phase"], gen_ch=cfg["res_ch"]),
            gain   = cfg["res_gain"],
            length = cfg["res_readout_length"],
        )
        self.sync_all(self.us2cycles(1))

    def body(self):
        self.pulse(self.cfg["qubit_ch"])  # PLAY PROBE PULSE
        self.sync_all(self.us2cycles(0.05))  # ALIGN CHANNELS AND WAIT 50NS
        # TRIGGER MEASUREMENT, PLAY MEASUREMENT PULSE, WAIT FOR QUBIT TO RELAX
        self.measure(
            pulse_ch        = self.cfg["res_ch"],
            adcs            = [0, 1],
            adc_trig_offset = self.cfg["adc_trig_offset"],
            wait            = True,
            syncdelay       = self.us2cycles(self.cfg["relax_delay"]),
        )

class RandomizedBenchmarking2GainSweep(RAveragerProgram):
    def initialize(self):
        cfg = self.cfg
        self.declare_gen(ch=cfg["res_ch"], nqz=1)  # READOUT
        self.declare_gen(ch=cfg["qubit_ch"], nqz=2)  # QUBIT
        for ch in [0,1]:  # CONFIGURE THE READOUT LENGTHS AND DOWNCONVERSION FREQUENCIES
            self.declare_readout(
                ch     = ch,
                length = cfg["res_readout_length"],
                freq   = cfg["res_freq"],
                gen_ch = cfg["res_ch"],
            )
        self.q_rp   = self.ch_page(self.cfg["qubit_ch"])                          # GET REGISTER PAGE FOR QUBIT_CH
        self.r_gain = self.sreg(cfg["qubit_ch"], "gain")  # get gain register for qubit_ch
        self.r_freq = self.sreg(cfg["qubit_ch"], "freq")                          # GET FREQUENCY REGISTER FOR QUBIT_CH
        f_res       = self.freq2reg(cfg["res_freq"], gen_ch=cfg["res_ch"], ro_ch=0)  # CONVERT F_RES TO DAC REGISTER VALUE
        # ADD QUBIT PULSE
        self.add_pulse(
            ch    = cfg["qubit_ch"],
            name  = cfg["qubit_pulse_name"],
            idata = cfg["qubit_i_data"],
            qdata = cfg["qubit_q_data"],
        )
        # ADD QUBIT AND READOUT PULSES TO RESPECTIVE CHANNELS
        self.set_pulse_registers(
            ch       = cfg["qubit_ch"],
            style    = "arb",
            gain     = cfg["qubit_gain"],
            waveform = cfg["qubit_pulse_name"],
            outsel   = "input",
            freq     = 0, #ARTIFACT OF ADAPTING QICK SW
            phase    = 0, #ARTIFACT OF ADAPTING QICK SW
        )
        self.set_pulse_registers(
            ch     = cfg["res_ch"],
            style  = "const",
            freq   = f_res,
            phase  = self.deg2reg(cfg["res_phase"], gen_ch=cfg["res_ch"]),
            gain   = cfg["res_gain"],
            length = cfg["res_readout_length"],
        )
        self.sync_all(self.us2cycles(1))

    def body(self):
        self.pulse(self.cfg["qubit_ch"])  # PLAY PROBE PULSE
        self.sync_all(self.us2cycles(0.05))  # ALIGN CHANNELS AND WAIT 50NS
        # TRIGGER MEASUREMENT, PLAY MEASUREMENT PULSE, WAIT FOR QUBIT TO RELAX
        self.measure(
            pulse_ch        = self.cfg["res_ch"],
            adcs            = [0, 1],
            adc_trig_offset = self.cfg["adc_trig_offset"],
            wait            = True,
            syncdelay       = self.us2cycles(self.cfg["relax_delay"]),
        )

    def update(self):
        self.mathi(
            self.q_rp, self.r_gain, self.r_gain, "+", self.cfg["step"]
        )  # update gain of the Gaussian pi pulse

class RandomizedBenchmarking2GainSweepSingleShot(RAveragerProgram):
    def initialize(self):
        cfg = self.cfg
        self.declare_gen(ch=cfg["res_ch"], nqz=1)  # READOUT
        self.declare_gen(ch=cfg["qubit_ch"], nqz=2)  # QUBIT
        for ch in [0,1]:  # CONFIGURE THE READOUT LENGTHS AND DOWNCONVERSION FREQUENCIES
            self.declare_readout(
                ch     = ch,
                length = cfg["res_readout_length"],
                freq   = cfg["res_freq"],
                gen_ch = cfg["res_ch"],
            )
        self.q_rp   = self.ch_page(self.cfg["qubit_ch"])                          # GET REGISTER PAGE FOR QUBIT_CH
        self.r_gain = self.sreg(cfg["qubit_ch"], "gain")  # get gain register for qubit_ch
        self.r_freq = self.sreg(cfg["qubit_ch"], "freq")                          # GET FREQUENCY REGISTER FOR QUBIT_CH
        f_res       = self.freq2reg(cfg["res_freq"], gen_ch=cfg["res_ch"], ro_ch=0)  # CONVERT F_RES TO DAC REGISTER VALUE
        # ADD QUBIT PULSE
        self.add_pulse(
            ch    = cfg["qubit_ch"],
            name  = cfg["qubit_pulse_name"],
            idata = cfg["qubit_i_data"],
            qdata = cfg["qubit_q_data"],
        )
        # ADD QUBIT AND READOUT PULSES TO RESPECTIVE CHANNELS
        self.set_pulse_registers(
            ch       = cfg["qubit_ch"],
            style    = "arb",
            gain     = cfg["start"],
            waveform = cfg["qubit_pulse_name"],
            outsel   = "input",
            freq     = 0, #ARTIFACT OF ADAPTING QICK SW
            phase    = 0, #ARTIFACT OF ADAPTING QICK SW
        )
        self.set_pulse_registers(
            ch     = cfg["res_ch"],
            style  = "const",
            freq   = f_res,
            phase  = self.deg2reg(cfg["res_phase"], gen_ch=cfg["res_ch"]),
            gain   = cfg["res_gain"],
            length = cfg["res_readout_length"],
        )
        self.sync_all(self.us2cycles(1))

    def body(self):
        # trigger measurement, play measurement pulse, wait for qubit to relax
        self.measure(
            pulse_ch=self.cfg["res_ch"],
            adcs=[0, 1],
            adc_trig_offset=self.cfg["adc_trig_offset"],
            wait=True,
            syncdelay=self.us2cycles(self.cfg["delta_t"]),
        )
        # play probe pulse
        self.pulse(ch=self.cfg["qubit_ch"])
        self.sync_all(self.us2cycles(0.001))# align channels
        # Measure again
        self.measure(
            pulse_ch=self.cfg["res_ch"],
            adcs=[0, 1],
            adc_trig_offset=self.cfg["adc_trig_offset"],
            wait=True,
            syncdelay=self.us2cycles(self.cfg["relax_delay"]),
        )

    def update(self):
        self.mathi(
            self.q_rp, self.r_gain, self.r_gain, "+", self.cfg["step"]
        )  # update gain of the Gaussian pi pulse
        
    def acquire(self, soc, load_pulses=True, progress=False):
        xpts, avg_di, avg_dq = super().acquire(soc, load_pulses=load_pulses, progress=progress)
        self.xpts   = xpts
        self.avg_di = avg_di
        self.avg_dq = avg_dq
        #
        shots_i0 = (
            self.di_buf[0].reshape((len(self.xpts), self.cfg["reps"], 2))
            / self.cfg["res_readout_length"]
        )
        shots_q0 = (
            self.dq_buf[0].reshape((len(self.xpts), self.cfg["reps"], 2))
            / self.cfg["res_readout_length"]
        )
        #
        return xpts, shots_i0, shots_q0