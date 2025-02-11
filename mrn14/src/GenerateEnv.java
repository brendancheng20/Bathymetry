

import java.io.BufferedWriter;
import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.util.ArrayList;

public class GenerateEnv {


	/**
	 * This class shows how to create an Environment File in Java
	 * @author maddienelson
	 * @param args
	 * @throws IOException 
	 */
	static String FS = System.getProperty("file.separator");
	/**Variables to change:
	 * FILE_PATH: change this to the file path in your computer where you have a folder 
	 * in which you want the files to be created. Note: this program does not  create a folder for you.
	 * Additionally, if you try to run the program and create a file with the same name as a file that
	 * already exits in that folder, it will tell you so and not overwrite the original file.
	 * NUM_TEST_FILES: This is the number of test files you would like to produce.
	 * FILE_NAME: The name that you want each file to have. It will generate "FILE_NAME0", "FILE_NAME1" ...
	 */
	public static final String FILE_PATH = FS+"Users"+FS+"maddienelson"+FS+"Documents"+FS+"Bathymetry";
	public static final int NUM_TEST_FILES = 10;
	public static final String ENV = ".env";
	public static final String NL = "\n";
	public static final String SPACE = "  ";
	public static final String BIG_SPACE = "                     ";
	
	//File Names can be changed.
	public static ArrayList<String> FILE_NAMES = new ArrayList<String>(){{
	    add("Washington");
	    add("Adams");
	    add("Jefferson");
	    add("Madison");
	    add("Monroe");
	    add("Quincy");
	    add("Jackson");
	    add("Van_Buren");
	    add("Harrison");
	    add("Tyler");
	    add("Polk");
	    add("Taylor");
	    add("Fillmore");
	    add("Pierce");
	    add("Buchanan");
	    add("Lincoln");
	}};
	
	/**Variables to change:*/
	//the frequency in (Hz)
	public static final double FREQ = 30000.0;
	//the number of NMEDIA
	private static final int NMEDIA = 1;
	//the SSPOPT (Analytic or C-Linear interpolation)
	private static final String SSPOPT = "'CVW'";
	//the Different Depth Values of bottom (m)
	private static final double DEPTH1 = 51;
	private static final double DEPTH2 = 0.0;
	private static final double DEPTH3 = 20.0;
	//Depth Values (vertical)
	private static final double VAL1 = 0;
	private static final double VAL2 = 10;
	private static final double VAL3 = 20;
	private static final double NUM1 = 20.0;
	private static final double NUM2 = 1600.00;
	private static final double NUM3 = 0.0;
	private static final double NUM4 = 1.8;
	private static final double NUM5 = 0.8;
	//Nsx number of source coordinates in x
	private static final double NSX = 1;
	// x coordinate(s) of source (km)
	private static final double XCORD_SOURCE = -0.1;
	private static final double XCORD_SOURCE2 = -0.1;
	//NSY number of source coordinates in y
	private static final double NSY = 1;
	// y coordinate(s) of source (km)
	private static final double YCORD_SOURCE = -0.250;
	//The number of source depths
	private static final double NSD = 1;
	// The source depths (m)
	private static double SD;
	// The number of receiver depths
	private static final double NRD = 3;
	// The receiver depths (m)
	private static double RD0;
	private static double RD1;
	// The number of receiver ranges
	private static final double NR = 1;
	// The receiver ranges (km)
	private static final double R0 = 0;
	private static final double R1 = 0.001;
	// The number of receiver bearings (radial)
	private static final double NTHETA = 3;
	// Bearing Angles (degrees)
	private static final double BANG2 = 120.0;
	private static final double BANG1 = 60.0;
	private static final double BANG0 = 0.0;
	private static final String RCIS = "'AB   3'";
	// Number of beams in elevation
	private static final double NALPHA1 = 300;
	private static final double NALPHA2 = 1;
	// Beam elevation angles (degrees) (negative angles toward surface)
	private static final double ALPHA1 = -20;
	private static final double ALPHA2 = 20;
	// Number of beams in azimuth
	private static final double NBETA2 = 1;
	private static final double NBETA1 = 361;
	// Beam azimuth angles (degrees) (math convention with 0 degrees pointing along the x-axis
	private static final double BETA1 = 0;
	private static final double BETA2 = 360;
	// The step size used for tracing the rays (m)
	private static final double STEP2 = 1;
	private static final double STEP1 = 0.0;
	private static final double STEP3 = 1;
	private static final double STEP4 = 50.0;


	public static void main(String[] args) throws IOException {

		for(int fileNum = 1; fileNum<NUM_TEST_FILES+1; fileNum++) {
			initMakeFiles(fileNum);
		}

	}
	
	
	private static void initMakeFiles(int fileNum) throws IOException {
		String envFileName = FILE_PATH+FS+FILE_NAMES.get(fileNum)+ENV;
		File envFile = new File(envFileName);
		checkFile(envFile, envFileName);
		makeENVFile(fileNum,envFile);		
	}


	private static void makeENVFile(int fileNum, File envFile) throws IOException {
		String str = createENVString(fileNum);
		writeToFile(envFile, str);		
	}


	private static String createENVString(int fileNum) {
		StringBuilder str = new StringBuilder();
		SD = (double) fileNum;
		double delta = 0.1;
		RD0 = SD;
		RD1 = SD+delta;
		str.append("'"+FILE_NAMES.get(fileNum)+" (3D run)' ! TITLE"+NL);
		str.append(FREQ+BIG_SPACE+"! FREQ (Hz)"+NL);
		str.append(NMEDIA+BIG_SPACE+"! NMEDIA"+NL);
		str.append(SSPOPT+BIG_SPACE+"! SSPOPT (Analytic or C-Linear interpolation)"+NL);
		str.append(DEPTH1+SPACE+DEPTH2+SPACE+DEPTH3+SPACE+"! DEPTH of bottom (m)"+NL);
		str.append(BIG_SPACE+VAL1+SPACE+"/"+NL);
		str.append(BIG_SPACE+VAL2+SPACE+"/"+NL);
		str.append(BIG_SPACE+VAL3+SPACE+"/"+NL);
		str.append("'A~' 0.0"+ NL); 
		str.append(NUM1+SPACE+NUM2+SPACE+NUM3+SPACE+NUM4+SPACE+NUM5+SPACE+"/"+NL);
		str.append(NSX+BIG_SPACE+"! Nsx number of source coordinates in x"+NL);
		str.append(XCORD_SOURCE+SPACE+XCORD_SOURCE2+SPACE+"/"+BIG_SPACE+"! x coordinate of source (km)"+NL);
		str.append(NSY+BIG_SPACE+"! Nsy number of source coordinates in y"+NL);
		str.append(YCORD_SOURCE+SPACE+"/"+BIG_SPACE+"! y coordinate of source (km)"+NL);
		str.append(NSD+BIG_SPACE+"! NSD"+NL);
		str.append(SD+SPACE+"/"+BIG_SPACE+"! SD(1:NSD) (m)"+NL);
		str.append(NRD+BIG_SPACE+"! NRD"+NL);
		str.append(RD0+SPACE+RD1+SPACE+"/"+BIG_SPACE+"! RD(1:NRD) (m)"+NL);
		str.append(NR+BIG_SPACE+"! NR"+NL);
		str.append(R0+SPACE+R1+SPACE+"/"+BIG_SPACE+"! R(1:NR) (km)"+NL);
		str.append(NTHETA+BIG_SPACE+"! Ntheta (number of bearings)"+NL);
		str.append(BANG0+SPACE+BANG1+SPACE+BANG2+SPACE+"/"+BIG_SPACE+"! bearing angles (degrees)"+NL);
		str.append(RCIS+BIG_SPACE+"! 'R/C/I/S'"+NL);
		str.append(NALPHA1+SPACE+NALPHA2+BIG_SPACE+"! NALPHA"+NL);
		str.append(ALPHA1+SPACE+ALPHA2+SPACE+"/"+BIG_SPACE+"! alpha1, 2 (degrees) Elevation/declination angle fan"+NL);
		str.append(NBETA1+SPACE+NBETA2+BIG_SPACE+"! Nbeta"+NL);
		str.append(BETA1+SPACE+BETA2+SPACE+"/"+BIG_SPACE+"! beta1, beta2 (degrees) bearine angle fan"+NL);
		str.append(STEP1+SPACE+STEP2+SPACE+STEP3+SPACE+STEP4+BIG_SPACE+"! STEP (m), Box%x (km) Box%y (km) Box%z (m)"+NL);
		return str.toString();
	}


	private static void checkFile(File file, String name) throws IOException {
		if(file.createNewFile()){
			System.out.println(name+" File Created");
		}
		else {
			System.out.println("File "+name+" already exists");
		}		
	}

	private static void writeToFile(File file, String str) throws IOException {
		BufferedWriter writer = new BufferedWriter(new FileWriter(file));
		writer.write(str);
		writer.close();			
	}
}
