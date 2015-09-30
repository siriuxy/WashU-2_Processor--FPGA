import java.io.*;
import java.util.*;

/** Assembler for WashU-2 processor.
 *  This is a very basic assembler for the WashU-2 processor that converts
 *  programs written in a simple assembly language to machine instructions
 *  for the processor. More specifically, the output takes the form of
 *  VHDL initialization clauses that can be inserted into the VHDL
 *  specification for the processor's ram module.
 *  
 *  The instructions recognized by the assembler are listed below.
 *  Each instruction may include an optional label (terminated by a colon)
 *  and most include a single required argument
 *
 *  [label:]  halt
 *  [label:]  negate
 *  [label:]  lShift
 *  [label:]  rShift
 *  [label:]  enInt
 *  [label:]  disInt
 *  [label:]  setVec
 *  [label:]  retInt
 *  [label:]  branch  target
 *  [label:]  brZero  target
 *  [label:]  brPos   target
 *  [label:]  brNeg   target
 *  [label:]  iBranch target
 *  [label:]  cLoad   value
 *  [label:]  dLoad    location
 *  [label:]  iLoad   location
 *  [label:]  dStore  location
 *  [label:]  iStore  location
 *  [label:]  add     location
 *  [label:]  and     location
 *  [label:]  or      location
 *
 *  The target of the branch instructions may be either a numeric
 *  constant in the range -128 to +127, or the label of some instruction.
 *  In the former case, the target is interpreted as the target offset,
 *  and is directly encoded in the branch instruction. In the latter case,
 *  the offset to the target is calculated. Note that in this case,
 *  the computed offset must be within the range supported by the
 *  instruction set [-128,127]. For the indirect branch instruction,
 *  the target is the location through which the branch takes place.
 *  The "ultimate target" is the location stored at the "initial target".
 *
 *  For the constant load instruction, the value argument is a constant
 *  that must be in the range [-2048,2047]. It can be expressed in either
 *  signed decimal, or hexadecimal. It is interpreted as hexadecimal if
 *  there is no negative sign and the first digit is 0. A label can also
 *  be used here, but the associated address must still be in the range
 *  [-2048,2047] which means that this can only really be used to refer
 *  to labels associated with addresses 0..2047.
 *  
 *  The location argument for the instructions that access memory
 *  can be either a numeric value or a label. In either case, the
 *  address referred to by the location argument must be on the same
 *  memory page as the instruction. That is, the top four bits of the
 *  referenced address must be the same as the top four bits of the
 *  address where the instruction is located.
 *
 *  The assembler also implements a location directive, which takes the form
 *
 *         location address
 *
 *  Here, the address argument is a hexadecimal value and its first digit
 *  must be zero. This generates no machine instruction but does advance
 *  the internal location variable that the assembler uses to place instructions
 *  into memory. This internal variable is incremented every time an
 *  an instruction is emitted. A location directive that would reduce
 *  the value of the internal location variable is an error.
 *
 *  The assembler also recognizes lines of the form
 *
 *  [label:]  value
 *
 *  where value is a signed decimal or hexadecimal number, or a label.
 *  This places the specified value at the current memory location and
 *  increments the assembler's internal location variable. If value is
 *  a label, then it is the address associated with that label that
 *  is stored in the current memory location.
 *
 *  The assembler treats the sequence "--" as the start of a comment
 *  that continues to the end of the line. Comments are copied to the
 *  output, along with the generated instructions.
 */

public class Assembler {

	private static Map<String,Integer> symTbl;  // symbol table
	private static int location;		    // current memory location

	/** Main method for static Assembler class.
	 *  Reads specified input file twice. On the first pass,
	 *  it checks for errors and determines the memory location
	 *  associated with each label. On the second pass, it generates
 	 *  instructions, in the form of VHDL intialization clauses.
	 */
	public static void main(String[] args) {
		// open file
		if (args.length != 1) {
			System.err.println("Missing required input file");
			System.exit(1);
		}
		Scanner in = null;
		try {
                        in = new Scanner(new File(args[0]));
		} catch (Exception e) {
                        System.err.println("Assembler: cannot open input file");
                        System.err.println(e);
                        System.exit(1);
                }

		// first pass
		symTbl = new HashMap<String,Integer>();
		location = 0;
		if (!pass1(in)) {
                        System.err.println("halting after first pass");
                        System.exit(1);
                }

		// second pass
		try {
                        in = new Scanner(new File(args[0]));
		} catch (Exception e) {
                        System.err.println("Assembler: cannot open input file");
                        System.err.println(e);
                        System.exit(1);
                }
		location = 0;
		if (!pass2(in)) {
                        System.err.println("stopped before end of "
					   + "second pass");
                        System.exit(1);
                }
	}

	/** Defines instructions and key properties */
	private enum Instruction {
		//      name      opCode  len hasArg
                UNDEF("undefined", 0x0000, 0, false),
                HALT(	"halt",	   0x0000, 4, false),
                NEGATE(	"negate",  0x0001, 4, false),
                LSHIFT(	"lShift",  0x0002, 4, false),
                RSHIFT(	"rShift",  0x0003, 4, false),
                ENINT(	"enInt",   0x0ff0, 4, false),
                DISINT(	"disInt",  0x0ff1, 4, false),
                SETVEC(	"setVec",  0x0ff2, 4, false),
                RETINT(	"retInt",  0x0ff3, 4, false),
                BRANCH(	"branch",  0x0100, 2, true),
                BRZERO(	"brZero",  0x0200, 2, true),
                BRPOS(	"brPos",   0x0300, 2, true),
                BRNEG(	"brNeg",   0x0400, 2, true),
                IBRANCH("iBranch", 0x0500, 2, true),
                CLOAD(	"cLoad",   0x1000, 1, true),
                LOAD(	"dLoad",   0x2000, 1, true),
                ILOAD(	"iLoad",   0x3000, 1, true),
                STORE(	"dStore",  0x5000, 1, true),
                ISTORE(	"iStore",  0x6000, 1, true),
                ADD(	"add",     0x8000, 1, true),
                AND(	"and",     0xc000, 1, true),
                OR(	"or",      0xd000, 1, true),
		LOC("location",	   0x0000, 0, true);

		public final String opName;
                public final int opCode;
		public final int opLen;
		public final boolean hasArg;

		/** Constructor for an Instruction value. */
                Instruction(String opName, int opCode, int opLen,
			       boolean hasArg) {
			this.opName = opName; this.opCode = opCode;
			this.opLen = opLen; this.hasArg = hasArg;
		}

		/** Determine the instruction represented by a given string.
		 *  @param name is a String that represents an instruction,
		 *  or the the location directive
		 *  @return the integer value of the Instruction or
		 *  Instruction.UNDEF if the given string does not match 
		 *  any defined instruction
		 */
		public static Instruction getInstruction(String name) {
			for (Instruction i: values()) {
				if (name.equals(i.opName)) return i;
			}
			return Instruction.UNDEF;
		}
        }

	/** Determine if a string represents a signed decimal constant.
	 *  @param s is a String
	 *  @return true if s represents a signed decimal constant,
	 *  else false
	 */
	public static boolean numericArg(String s) {
		return s != null && s.matches("([1-9][0-9]*)|(-[1-9][0-9]*)");
	}

	/** Determine if a string represents a hexadecimal constant.
	 *  @param s is a String
	 *  @return true if s represents a hexadecimal constant,
	 *  else false; the first character must be '0'
	 */
	public static boolean hexArg(String s) {
		return s != null && s.matches("(0[0-9a-fA-F]*)");
	}

	/** Determine if a string represents an acceptable word.
	 *  @param s is a String
	 *  @return true if s represents a "word" (that is, an
	 *  alphanumeric string that starts with an alphabetic
	 *  character), else false
	 */
	public static boolean wordArg(String s) {
		return s != null && s.matches("[a-zA-Z][a-zA-Z0-9_]*");
	}

	/** Represents the components of an input line. */ 
	public static class LineParts {
		public String label;
		public Instruction inst;
		public String arg;
		public String comment;
		public boolean blank;
		public String errMsg;
		public LineParts() {
			label = null; inst = Instruction.UNDEF; arg = null;
			comment = null; blank = true; errMsg = null;
		}
	}

	/** Parse an input line and return the results in a new Line object.
	 *  @param lineBuf is a String that represents an input line
	 *  @return a new Line object that contains the components of the
 	 *  provided input line
	 */
	private static LineParts parseLine(String lineBuf) {
		Scanner lineScanner = new Scanner(lineBuf);
		LineParts thisLine = new LineParts();
		boolean foundInstruction = false;
		while (lineScanner.hasNext()) {
			if (lineScanner.hasNext("--.*")) {
				thisLine.comment = lineScanner.findInLine("--.*");
				thisLine.blank = false;
				break;
			}
			String tok = lineScanner.next();
			if (thisLine.label == null) { // check for label
				if (tok.charAt(tok.length()-1) == ':') {
					thisLine.label = tok.substring(
							 0,tok.length()-1); 
					thisLine.blank = false;
					continue;
				}
				thisLine.label = ""; // no label on this line
			}

			if (!foundInstruction) {
				thisLine.inst = Instruction.getInstruction(tok);
				if (!thisLine.inst.equals(Instruction.UNDEF)) {
					thisLine.blank = false;
					foundInstruction = true;
					continue;
				}
			}

			if (thisLine.arg == null) {
				thisLine.arg = tok;  // must be the argument
				thisLine.blank = false;
				continue;
			}

			// if we get here, there's a syntax error
			thisLine.errMsg = "unrecognized token: " + tok;
			break;
		}
		return thisLine;
	}
			
	/** Read input file and build symbol table.
	 *  Every label in the input file is entered into the symbol
	 *  table, along with its associated address.
	 *  @param in is a Scanner bound to the input file
	 *  @return true if the file is processed with no errors;
	 *  else false.
	 */
	private static boolean pass1(Scanner in) {
		int lineNum = 0;
		boolean status = true;
		while (in.hasNextLine()) {
			lineNum++;
			String lineBuf = in.nextLine();
			LineParts thisLine = parseLine(lineBuf);
			if (thisLine.blank) continue;
			if (thisLine.errMsg != null) {
				System.err.println("Error on line " + lineNum
					+ " (" + thisLine.errMsg + ")");
				status = false; continue;
			}
			// check for a label and enter in symbol table
			if (thisLine.label != null &&
			    thisLine.label.length() > 0) {
				if (symTbl.get(thisLine.label) != null) {
					System.err.println("Error on line " +
						lineNum + "(duplicate label)");
					status = false; continue;
				}
				symTbl.put(thisLine.label,location);
			}
			if (thisLine.inst == Instruction.UNDEF) {
				if (thisLine.arg != null) location++;
				continue;
			}

			// check that argument is present when expected
			if (thisLine.inst.hasArg != (thisLine.arg != null)) {
				System.err.println("Error on line " + lineNum +
					"(argument mismatch)");
				status = false; continue;
			}
				
			// for location directives, update location
			if (thisLine.inst == Instruction.LOC) {
				if (!hexArg(thisLine.arg)) {
					System.err.println("Error on line " +
					    lineNum + "(location directive " +
					    "requires hexadecimal argument)");
					status = false; continue;
				}
				int nuLoc = Integer.parseInt(thisLine.arg,16);
				if (nuLoc < location) {
					System.err.println("Error on line " +
					    lineNum + "(decreasing location)");
					status = false; continue;
				}
				location = nuLoc;
			} else {
				location++; continue;
			}
		}
		return status;
	}
			
	/** Read the input file and generate instructions.
	 *  During this pass, instructions are generated in the
	 *  form of VHDL initialization clauses and printed on the
	 *  standard output. The addresses for instructions are computed
	 *  using the information stored in the sysmbol table during
	 *  the first pass. Comments are also copied through to the output.
	 *  @param in is a Scanner bound to the input file
	 *  @return true if the input file is processed without errors,
	 *  else false
	 */
	private static boolean pass2(Scanner in) {
		int lineNum = 0;
		while (in.hasNextLine()) {
			lineNum++;
			String lineBuf = in.nextLine();
			LineParts thisLine = parseLine(lineBuf);
			if (thisLine.blank) continue;

			// Determine the value of the argument field
			Integer argVal = 0;
			if (thisLine.arg != null) {
				if (numericArg(thisLine.arg)) {
					argVal = Integer.parseInt(thisLine.arg);
				} else if (hexArg(thisLine.arg)) {
					argVal = Integer.parseInt(
							 thisLine.arg,16);
				} else if (wordArg(thisLine.arg)) {
					argVal = symTbl.get(thisLine.arg);
					if (argVal == null) {
						System.err.println("Error on " +
							"line " + lineNum +
							"(reference to " +
							"undefined label)");
						return false;
					}
				} else {
					System.err.println("Error on line " + 
						lineNum + "(invalid argument)");
					return false;
				}
			}

			if (thisLine.inst == Instruction.UNDEF &&
			    thisLine.arg != null) {
				emit(location,Instruction.UNDEF,argVal);
				if (thisLine.comment != null)
					System.out.print("        "
						+ thisLine.comment);
				System.out.println("");
				location++; continue;
			}

			if (thisLine.inst == Instruction.UNDEF &&
			    thisLine.comment != null) {
				System.out.println("    " + thisLine.comment);
				continue;
			}

			if (thisLine.inst == Instruction.UNDEF) continue;

			switch (thisLine.inst) {
			case LOC:
				location = argVal; continue;
			case HALT:
			case NEGATE:
			case LSHIFT: case RSHIFT:
			case ENINT: case DISINT: case SETVEC: case RETINT:
				emit(location,thisLine.inst,0);
				location++; break;
			case BRANCH: case BRZERO: case BRPOS: case BRNEG:
			case IBRANCH:
				int diff;
				if (wordArg(thisLine.arg))
					diff = argVal - location;
				else
					diff = argVal;
				if (diff < -128 || diff > 127) {
					System.err.println("Error on line " +
						lineNum +
						"(branch range exceeded)");
					return false;
				}
				emit(location,thisLine.inst,diff);
				location++; break;
			case CLOAD:
				if (argVal < -2048 || argVal > 2047) {
					System.err.println("Error on line " +
						lineNum +
						"(constant range exceeded)");
					return false;
				}
				emit(location,thisLine.inst,argVal);
				location++; break;
			case LOAD: case ILOAD:
			case STORE: case ISTORE:
			case ADD: case AND: case OR:
				if ((argVal & 0xf000) != (location & 0xf000)) {
					System.err.println("Error on line " +
						lineNum +
						"(target on wrong page)");
					return false;
				}
				emit(location,thisLine.inst,argVal);
				location++; break;
			}
			if (thisLine.comment != null)
				System.out.print("        "
					+ thisLine.comment);
			System.out.println("");
		}
		return true;
	}

	/** Print an instruction.
	 *  Instructions are printed in the form of VHDL initialization clauses.
	 *  @param adr is the address for the instruction
	 *  @param inst is the instruction to be printed
	 *  @param arg is the argument for the instruction
	 */
	private static void emit(int adr, Instruction inst, int arg) {
		arg &= ((1 << 16-4*inst.opLen) - 1);
		int instruction = inst.opCode | arg;
		System.out.print("    16#" + hexString(adr) + "# => x\"" +
				 hexString(instruction) + "\",");
	}

	/** Constant array defining hex digits. */
	private static final char[] hexDigits = {
		'0','1','2','3','4','5','6','7','8','9','a','b','c','d','e','f'
	};

	/** Return a hexadecimal string representing the 16 bit integer.
	 *  Need to resort to this to suppress the "0x" that Java includes
	 *  when it prints a hex value.
	 *  @param x is the value to be converted to a string.
	 *  @return a new String objet that corresponds to x
	 */
	private static String hexString(int x) {
		return "" + hexDigits[(x >> 12) & 0xf]
			  + hexDigits[(x >>  8) & 0xf]
			  + hexDigits[(x >>  4) & 0xf]
			  + hexDigits[x & 0xf];
	}
}
