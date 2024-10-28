from distutils.log import debug
import sys
class Assembler:
    def __init__(self,ins_list_name,input_file,output_file,debug) -> None:
        self.ins_list_name =  ins_list_name
        self.ins_opcode_mapping = dict()
        self.opcode_ins_mapping = dict()
        self.output_file = output_file
        self.input_file =  input_file
        self.debug_level =debug
        self.load_mapping()


    def load_mapping(self):

        with open(self.ins_list_name,'r') as ins_lst:
            for line in ins_lst.readlines():
                # print(line)
                ins,opcode =  line.split("\t")
                memonic = ins.split(" ")[0]
                opcode = opcode.strip()
                self.ins_opcode_mapping[memonic]=opcode
                if "rt, ra, rb, rc" in ins:
                    self.opcode_ins_mapping[opcode]=[1,ins]
                elif "rt, ra, rb" in ins:
                    self.opcode_ins_mapping[opcode]=[0,ins]
                elif "rt, ra, imm7" in ins:
                    self.opcode_ins_mapping[opcode]=[2,ins]
                elif "rt, ra, imm8" in ins:
                    self.opcode_ins_mapping[opcode]=[3,ins]
                elif "rt, ra, imm10" in ins or "rt, imm10(ra)" in ins :
                    self.opcode_ins_mapping[opcode]=[4,ins]
                elif "rt, imm16" in ins or "imm16" in ins :
                    self.opcode_ins_mapping[opcode]=[5,ins]
                elif "rt, imm18" in ins:
                    self.opcode_ins_mapping[opcode]=[6,ins]
                else:
                    if "nop" in ins:
                        print("nop")
                        self.opcode_ins_mapping[opcode]=[7,ins]
                    elif "stop" in ins:
                        self.opcode_ins_mapping[opcode]=[7,ins]

                # #print(ins,opcode)
        # #print(self.opcode_ins_mapping)
        # #print(self.ins_opcode_mapping)

    def parse_line(self,line):
        ins = line.strip()
        ins =ins.split("//")
        ins = ins[0].strip().split(" ")
        return ins

    def parse_input(self):

        with open(self.input_file,'r') as ins_lst, open(self.output_file,'w') as object:
            for line in ins_lst.readlines():
                ins = self.parse_line(line)
                memonic = ins[0]
                if "stop" in memonic:
                    break
                #print(memonic)
                opcode = self.ins_opcode_mapping[memonic]
                #print(opcode)
                format = self.opcode_ins_mapping[opcode]
                # print("format ",format)
                binary = self.compute(format,opcode,ins)
                object.write(binary+"\n")

    def parse_input_1(self):
        with open(self.input_file,'r') as ins_lst, open(self.output_file,'w') as object,open("debug.out",'w') as d_object:
            for line in ins_lst.readlines():

                ins = self.parse_line(line)
                memonic = ins[0]
                if "stop" in memonic:
                    break
                #print(memonic)
                opcode = self.ins_opcode_mapping[memonic]
                print(opcode)
                format = self.opcode_ins_mapping[opcode]
                # print("format ",format)
                binary = self.compute(format,opcode,ins)
                object.write(binary+"\n")
                if self.debug_level==2:
                    o_hex = '0x{0:0{1}X}'.format(int(binary,2),8)
                    d_object.write(str(binary)+"\t"+o_hex+"\t"+line)
                else:
                    d_object.write(str(binary)+"\t"+line)


    def compute(self,format,opcode,ins):
        ins_binary = "".zfill(32)
        print(format,ins_binary,len(ins_binary))
        print("ins {}".format(ins))
        if format[0] == 0:
            # opcode rt ra rb
            # op[0-10]rb[11-17]ra[18-24]rt[25-31]
            rt = bin(int(ins[1])).replace("0b","")
            ra = bin(int(ins[2])).replace("0b","")
            rb = bin(int(ins[3])).replace("0b","")
            #print(rt,ra,rb)
            rt = self.fill(rt,7)
            ra = self.fill(ra,7)
            rb = self.fill(rb,7)
            #print(rt,ra,rb)
            ins_binary = opcode+rb+ra+rt

        elif format[0] == 1:
            # opcode rt,ra,rb,rc
            # op[0-3]rt[4-10]rb[11-17]ra[18-24]rc[25-31]
            rt = bin(int(ins[1])).replace("0b","")
            ra = bin(int(ins[2])).replace("0b","")
            rb = bin(int(ins[3])).replace("0b","")
            rc = bin(int(ins[4])).replace("0b","")
            #print(rt,ra,rb)
            rt = self.fill(rt,7)
            ra = self.fill(ra,7)
            rb = self.fill(rb,7)
            rc = self.fill(rc,7)
            # print(rt,ra,rb,rc)
            ins_binary = opcode+rt+rb+ra+rc
        elif format[0] == 2:
            # opcode rt,ra,imm7
            # op[0-10]imm7[11-17]ra[18-24]rt[25-31]
            mask = 0b1111111
            rt = bin(int(ins[1])).replace("0b","")
            ra = bin(int(ins[2])).replace("0b","")
            imm7 = bin(int(ins[3]) & mask).replace("0b","")

            rt = self.fill(rt,7)
            ra = self.fill(ra,7)
            imm7 = self.fill(imm7,7)
            ins_binary = opcode+imm7+ra+rt

        elif format[0] == 3:
            # opcode rt,ra,imm8
            # op[0-9]imm8[10-17]ra[18-24]rt[25-31]
            mask = 0b11111111
            rt = bin(int(ins[1])).replace("0b","")
            ra = bin(int(ins[2])).replace("0b","")
            imm8 = bin(int(ins[3]) & mask).replace("0b","")
            rt = self.fill(rt,7)
            ra = self.fill(ra,7)
            imm8 = self.fill(imm8,8)
            ins_binary = opcode+imm8+ra+rt


        elif format[0] == 4:
            # opcode rt,ra,value
            # op[0-7]imm10[8-17]ra[18-24]rt[25-31]
            rt = bin(int(ins[1])).replace("0b","")
            rt = self.fill(rt,7)
            mask = 0b1111111111

            if '(' in format[1]:
                # opcode rt, symbol(ra)
                imm10 = ins[2].split('(')[0]
                ra = ins[2].split('(')[1][:-1]
            else:
                # opcode rt,ra,value
                imm10 = ins[3]
                ra = ins[2]

            # print(imm10,ra)
            imm10 = bin(int(imm10)  & mask).replace("0b","")
            imm10 = self.fill(imm10,10)

            ra = bin(int(ra)).replace("0b","")
            ra = self.fill(ra,7)
            ins_binary = opcode+imm10+ra+rt
        elif format[0] == 5:
            print(ins)
            mask = 0b1111111111111111
            if len(ins)==3:
                rt = bin(int(ins[1])).replace("0b","")
                imm16 = bin(int(ins[2]) & mask).replace("0b","")
            else:
                rt="0"
                imm16 = bin(int(ins[1]) & mask ).replace("0b","")

            print(rt,imm16)
            rt = self.fill(rt,7)
            imm16 = self.fill(imm16,16)
            print(rt,imm16)
            ins_binary = opcode+imm16+rt
        elif format[0] == 6:
            # opcode rt,value
            # op[0-8]imm16[9-24]rt[25-31]
            mask = 0b111111111111111111
            rt = bin(int(ins[1]) & mask).replace("0b","")
            rt = self.fill(rt,7)

            imm18 = bin(int(ins[2]) ).replace("0b","")
            imm18 = self.fill(imm18 ,18)
            ins_binary = opcode+imm18+rt
        else:
            ins_binary = opcode + self.fill("",32-len(opcode))



        #print(ins_binary,len(ins_binary))
        return ins_binary
    def fill(self,seq,width):
        neg = False
        if len(seq) > 0 and seq[0]=='-':
            neg = True
        seq =  seq.replace("-","")
        wide_seq = seq.zfill(width)

        if neg:
            wide_seq=str(1)+wide_seq[1:]
        return wide_seq



if len(sys.argv) ==1:
    print("Please mention the asm file: python assembler <input>.asm -o <out>")
    sys.exit(0)
input_file_name = sys.argv[1]
output_file_name = "out"
debug = 0
print(sys.argv)

print(sys.argv)
for i in range(1,len(sys.argv)):
    print("test ",sys.argv[i])
    if sys.argv[i] =='-o':
        print("afdasd")
        output_file_name = sys.argv[i+1]
        i=i+1

    if sys.argv[i] =='-d':
        debug=int(sys.argv[i+1])
        i=i+1

print(" fda ",input_file_name)
print("dfd ",output_file_name)
asm = Assembler(ins_list_name="instructions.lst", input_file=input_file_name,
                output_file=output_file_name,debug=debug)

print(debug)
if debug==0:
    asm.parse_input()
elif debug>=1:
    print("debug ")
    asm.parse_input_1()