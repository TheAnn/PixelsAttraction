
import generativedesign.*;
import processing.pdf.*;
import java.util.Calendar;
import java.util.Date;

boolean savePDF = false;
boolean saveToPrint = false;

Calendar startTime = Calendar.getInstance(); 

float cnt01, cnt02;
float valenceMean, arousalMean; //calculated inside load data
float valenceStd, arousalStd;

String fileName="0F.csv";

float Xvalence,Yarousal; //used for mapping X and Y position of attractors
int time;

//attractors parameters
int radius; //radius for attractors

float noise= 10*2/3 ; // noise in percentage, based on number of noise points (first number) in DBSCAN  ************* 

float strength = map(0.9, 0, 1, 0, 35); //strength of attractors
float rampS= 0.06;                // ramp on starting= initial point effect          **************  
float ramp = -map(noise, 0, 100, 0, 3); //ramp radius

int count = 350; //int(random(40,90)); //number of dots
float circleRadius = map(100-noise, 0, 100, 1, 1); //how spreaded are the initial points around the circle || Data noise 


int crclSize=280;

float finalnodeY, finalnodeX;

int left [][]=new int [2][count]; //2 2D arrays with values
int right [][]=new int [2][count];

//creating nodes  
int xCount=0; //initial value
int yCount = count;

ArrayList<Node> nodeArraylist; //vsetky spolu
ArrayList<ArrayList> linesList; //vsetky lines

Attractor myAttractor;

PointAnna[]points;
Table table;

void setup() {
  size(780, 680); 
  smooth();
  pixelDensity(2);
  strokeCap(ROUND);
  strokeJoin(ROUND);
  loadData();
  
  if (arousalMean>0 & valenceMean>0.65 || arousalMean>0.65 || valenceMean<-0.65){
    time=int(map((valenceStd+arousalStd)/2, 0, 1, 15, 30)); //mapping longer drawing time for higher intensity emotions
  }
  
  else {
    time=int(map((valenceStd+arousalStd)/2, 0, 1, 8, 165));
  }
  
  Xvalence = map(valenceMean, -1, 1, 0+60, 680-60);
  Yarousal = map(arousalMean, -1, 1, 680-60, 0+60);
  
  radius = int(map((valenceStd+arousalStd)/2, 0, 1, 80, 500));

  println("points= " +count + " and circle radius= " +circleRadius + " strength= " + strength+" ramp= " +ramp+ " radius= " +radius);

  println("initial position of attractors " + Xvalence + " || " +Yarousal+ " time: " + time +" noise: " +noise );

  makepoints(); //calculates the positions of points around a circle, and stores them in the 2D arrays. if circleRadius not 1, they are more spread, not following a clear circle line
  sortMe(left); //sorting them to be 
  sortMe(right);

  nodeArraylist = new ArrayList<Node>(10000);
  linesList=new ArrayList();

  initGrid(); // setup node grid. This is where I save the position of each node (from all the lines) into the array.

  myAttractor = new Attractor(0, 0); // setup attractor
  myAttractor.strength = strength;
  myAttractor.ramp = ramp;
  myAttractor.radius=radius;
}

boolean first=true;
int c = 0;
float noiseMax = map(noise, 0, 100, 1, 5);


void draw() {
  background(255);
  strokeWeight(0.3);
  stroke(0);
  fill(0);
  float lastx=0;
  float lasty=0;
  //ellipse(Xvalence, Yarousal, 2, 2);
  
  c++;
  cnt01+=0.7;
  cnt02+=0.98789;

  if (first) {
    myAttractor.ramp = rampS;
    myAttractor.x = Xvalence;
    myAttractor.y = Yarousal;
    first=false;
  } else {
    myAttractor.ramp = ramp;
    myAttractor.x = Xvalence+(noise(cnt01)-0.5)*350+c;
    myAttractor.y = Yarousal+(noise(cnt02)-0.5)*350+c;
  }

  if (c>30) {
    myAttractor.strength = -1*strength;
  }

  println("attractors position: "+ myAttractor.x +"|| "+ myAttractor.y);


  for (int i = 0; i < linesList.size(); i++) {  //loop for going through the nodes drawing them, and updating their position.
    ArrayList pointsOnLine=linesList.get(i);

    if (i==9 || i==117 || i==394 ) {
      stroke(0, 255, 255);
      strokeWeight(0.8);
    } else {
      stroke(0);
      strokeWeight(0.3);
    }

    for (int j=0; j<pointsOnLine.size(); j++) {
      Node node = (Node)pointsOnLine.get(j);
      myAttractor.attract(node);
      node.update();    

      finalnodeX=node.x;
      finalnodeY=node.y;      

      if (lastx>0) {      
        line(finalnodeX, finalnodeY, lastx, lasty);
      }
      lastx=finalnodeX;
      lasty=finalnodeY;
    }

    lastx=0;
    lasty=0;
  }

  Calendar calendarStop = Calendar.getInstance();
  calendarStop.add(Calendar.SECOND, -time);
  

  if (calendarStop.after(startTime))
  {
    noLoop();
  }
}

void loadData() {

  Table table = loadTable(fileName); //data file
  float[][] points = new float[2][table.getRowCount()-1];
  //points= new PointAnna[table.getRowCount()];  // The size of the array of Point objects is determined by the total number of rows in the CSV


  for (int i=1; i<table.getRowCount(); i++) { //accesing all table rows and storing them as object parameters

    TableRow row=table.getRow(i);

    float xax=(float)row.getDouble(4); //*(crclSize-60)+width/2;  //object parameters, x ax position and y ax position, normalizing
    float yax =(float)row.getDouble(5); //*(crclSize-60)+height/2-40;



    points[0][i-1] = xax;
    points[1][i-1] = yax;

    //println(xax,yax);
  }

  float[] meanX = meanAndStd(points[0]);
  float[] meanY = meanAndStd(points[1]);
  println("mean  is " + meanX[0], meanY[0]);
  println("std  is " + meanX[1], meanY[1]);
  valenceMean= meanX[0];
  arousalMean=meanY[0];
  valenceStd=meanX[1]; 
  arousalStd=meanY[1];
}

float[] meanAndStd(float numArray[])
{
  float[] ret = new float[2];
  float sum = 0.0, standardDeviation = 0.0;
  int length = numArray.length;

  for (float num : numArray) {
    sum += num;
  }

  float mean = sum/length;

  for (float num : numArray) {
    standardDeviation += Math.pow(num - mean, 2);
  }

  ret[0] = mean;
  ret[1] = (float)Math.sqrt(standardDeviation/length);

  return ret;
}

void sortMe(int[][] arr) {
  String [] sortArray= new String[count];
  //println("prva" + arr[0][0],arr[1][0]); 


  for (int j = 0; j < count; ++j) {       //Moving the data from Matrix to single array to be sorted
    String combineColumns; 
    combineColumns = str(arr[0][j]);   //Adding the two columns together, seperated by a "dash(-)"  
    //Converting the datatype to String, to fit a single array
    combineColumns = str(arr[1][j]) + "-" + combineColumns; //saving string with y position first
    sortArray[j] = combineColumns;
  }

  sortArray = sort(sortArray);  //Sorting, using processings sorting function

  for (int i = 0; i < count; ++i) {  //Moving the sorted data back in the Matrix
    String[] tmp = split(sortArray[i], "-"); //Using the split function, for each string in my array, and input the data into a temporary array (holding 2 numbers(rows))    
    arr[0][i] = int(tmp[1]); 
    arr[1][i] = int(tmp[0]); //Using the temp array, to write the data into the matrix again, flipping x,y position back
  }

  // println(""); println("FINAL RESULT"); //checking if sorting worked
  //for(int i = 0; i < 10; ++i) {
  // print(arr[0][i],arr[1][i]);
  // println("");
  //}
}

void makepoints() {

  for (int i=0; i<count; i++) {   //calculating coordinates for each point on the right side

    float angle = radians(180/float(count));
    float randomX = random(0, width);  
    float randomY = random(0, height);
    float circleX = width/2 + sin(angle*i)*(crclSize);
    float circleY = height/2 + cos(angle*i)*(crclSize);

    int x = floor(lerp(randomX, circleX, circleRadius)); 
    int y = floor(lerp(randomY, circleY, circleRadius));

    right [0][i]=x;
    right [1][i]=y;
  }


  for (int i=0; i<count; i++) {  //calculating coordinates for each point on left side
    float angle = radians(-180/float(count));
    float randomX = random(0, width);  
    float randomY = random(0, height);
    float circleX = width/2 + sin(angle*i)*(crclSize);
    float circleY = height/2 + cos(angle*i)*(crclSize);

    int x = floor(lerp(randomX, circleX, circleRadius)); 
    int y = floor(lerp(randomY, circleY, circleRadius));

    left [0][i]=x;
    left [1][i]=y;
  }  
  //drawing points

  //for (int i=0; i<count; i++){ 
  //fill(0);
  //ellipse(left[0][i],left [1][i],3,3);
  //ellipse(right [0][i],right [1][i],3,3);
}

void initGrid() {


  for (int y = 0; y < yCount; y++) {

    int middleToPoint = int(dist(width/2, left[1][y], left[0][y], left[1][y]));

    ArrayList<Node> nodesInOneLine =new ArrayList(); //vsetky body v jednej line

    for (int x = left[0][y]; x <= left[0][y]+2*middleToPoint; x++) {
      int xPos = x;
      int yPos = left[1][y];    

      Node myOneNode = new Node(xPos, yPos); //save position in Node object
      myOneNode.setBoundary(0, 0, width, height);
      myOneNode.setDamping(0.8);  //// 0.0 - 1.0

      nodeArraylist.add(myOneNode);
      nodesInOneLine.add(myOneNode);
    }

    linesList.add(nodesInOneLine);
  }
}


/////

void keyReleased() {  //saving
  if (key == 's' || key == 'S') saveFrame(timestamp()+"_####.png");
  if (key == 'p' || key == 'P') savePDF = true;
  println("I'm safed!");
}

String timestamp() {
  Calendar now = Calendar.getInstance();
  return String.format("%1$ty%1$tm%1$td_%1$tH%1$tM%1$tS", now);
}
