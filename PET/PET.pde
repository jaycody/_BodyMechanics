
/*jason stephens
 Proprioception Enhancement Tool (PET)
 ABQ School of Massage and Health Sciences
 2012.01
 
 PET:  a system and method for improving proprioception
 and encouraging healthy body mechanics in massage therapists.
 
 SETUP:  2 Kinects placed 20 feet apart are attached to a drop ceiling 10 feet
 above the ground.  The kinects face a massage tables positioned on the floor half way between
 the two kinects.  A Mac Mini running Processing and the SimpleOpenNI Library processes
 the incoming data from the kinects.  A depth image is then created allowing a therapist in training
 the opportunity for realtime self evaluaiton of his/her body mechanics.  
 
 NOTES:  Issues with Multiple Kinects on MacMini.  Possibly due to usb bus issues.  
 Tried every usb connection variation between the 2 kinects to insure Kinects were not on 
 same bus.  Also possibly due to low memory.  MacMini had 2 gigs.  Bumped to max at 8gig.
 Problem persisted.  Rare cases found on SimpleOpenNI forum.  They're working on it.  
 
 
 TODO:
 Done____Begin Peasy
 Done____draw simple point cloud
 Done____create and control one peasy variable
 
 DONE____create and control one peasy variable with ipad
 
 ____define functions to receive parameters for LR UP IO look
 ____attempt to pass functions from OSCevent.  just for testing purposes. likely call functions in draw
 
 ____add PEASY cam control to variables (perhaps issue with moving the coordinate system?
 
 ____add remainder of variables for standard movements
 ____then switch to ABQ computer and begin pCam hotspots
 
 DONE____drawCam with kinect.drawCamFrustum()
 ____draw the floor (see UserScene3D example)
 ____color user separate from background (see UserScene3D)
 ____remove background leaving only user and massage table.
 
 ____share PET via DropBox rather than push git updates
 
 FUTURE FUNCTIONALITY:
 ____create Kinect switching
 ____hotspot above therpists head
 ____where toggling between Kinects, return to previous camera angle
 ____//PeasyDragHandler will retain dampening effect seen by mouseXY

 
 */
import processing.opengl.*;
import SimpleOpenNI.*;
import peasy.*;
import oscP5.*;  // ipad action
import netP5.*;

SimpleOpenNI kinect1;
PeasyCam pCam;
OscP5 oscP5;


//iPad control variable
float lookLR = 0; //  Look Left/Right = /1/lookLR :  range 0-1 incoming 
float pLookLR =0; // previous val, so that Peasy aint flying around
float rcvLookLR = 0; //takes the value directly from the oscP5 event
float nowLookLR = 0; //receives the return value from calcLookLR();//

float lookUD = 0; // Look up down.  gonna change incoming range to -6,6 (or close to -2PI,2PI)
float pLookUD = 0;

float zoomIO = 0; //
float pZoomIO = 0;

float reset = 0;
float pCamReset = 0;

boolean setMirror = false;
boolean pSetMirror= false;

float swCam = 0; //DEBOUNCING !!
float pSwCam = 0;
boolean wasOn = true;
boolean isOn = true;


void setup () {
  size (1024, 768, OPENGL);

  //start oscP5 listening for incoming messages at port 8000
  oscP5 = new OscP5(this, 8000);

  pCam = new PeasyCam(this, 0, 0, 0, 1000); //initialize peasy

  kinect1 = new SimpleOpenNI (this);  //initialize 1 kinect
  kinect1.setMirror(true);//disable mirror and renable with set mirror button
  kinect1.enableDepth();
}

// create function to recv and parse oscP5 messages
void oscEvent (OscMessage theOscMessage) {

  String addr = theOscMessage.addrPattern();  //never did fully understand string syntaxxx
  float val = theOscMessage.get(0).floatValue(); // this is returning the get float from bellow

  if (addr.equals("/1/lookLR")) {  //remove the if statement and put it in draw
    rcvLookLR = val; //assign received value.  then call function in draw to pass parameter
   
  }
  else if (addr.equals("/1/lookUD")) {
    lookUD = val;
  }
  else if (addr.equals("/1/zoomIO")) {
    zoomIO = val;
  }

  else if (addr.equals("/1/reset")) {
    reset = val;
  }

  else if (addr.equals("/1/setMirror")) {
    setMirror = true;
  }

  else if (addr.equals("/1/showCamera")) {
    swCam = val;
  }
}

void draw() {
  //2nd part of Shiffman's suggestion for starting up full screen in second monitor
  //frame.setLocation(0, 0);  //set this to -1024 if secondary monitor is on the left

  background (0);
  kinect1.update();

  rotateX(PI); //rotate along the xPole 180 degrees
  //rotateY(PI);
  stroke(255);

 

 
  print("lookLR = " + lookLR);
  //rotateX(lookUD); //rotate around the X_pole (so look up down)
  println(" lookUD = " + lookUD);
  //scale(zoomIO); // aint so sure about messing with the scale, bro
  println(" scale = " + zoomIO);
  //because scale is like a multiplier, bro

  PVector [] depthPoints1 = kinect1.depthMapRealWorld(); //returns an array loads array

  for (int i = 0; i<depthPoints1.length; i+=5) {
    PVector currentPoint = depthPoints1 [i]; //extract PVector from this location and store it locally
    point (currentPoint.x, currentPoint.y, currentPoint.z);
  }

  //___TOGGLE SWITCHES

  //___________________
  //SetMirror Debounce Toggle:  if setMirror goes HIGH, then toggle mirror  
  if (setMirror !=pSetMirror) {
    if (setMirror) {
      kinect1.setMirror(!kinect1.mirror());
    }
  }
  pSetMirror = setMirror;
  setMirror = false;  //clear the boolean
  //_________________

  //_______
  //SHOW CAMERA DEBOUNCE TOGGLE:  
  //Please take picture of these few lines of code (3 hours easy);
  //4 variables needed to debounce a pushbutton used to toggle...
  if (swCam==1 && (swCam != pSwCam)) {
    if (wasOn) {
      isOn = false;
      wasOn =isOn;
    }
    else if (wasOn == false) {
      isOn = true;
      wasOn = isOn;
    }
  }
  pSwCam = swCam;

  if (isOn) {
    kinect1.drawCamFrustum();
  }
  //__________________


  //________________
  //RESET CAMERA TOGGLE
  //ahhhh, this debounce works.  placed after the formation of the point cloud
  //also made a difference with the flicker
  //reset cam position but only if we need to
  if (reset != pCamReset) {
    if (reset == 1) {
      pCam.reset(2500); //only move cam if we need to
    }
  }
  pCamReset = reset;
  //________________
  
  //+++++++CALL FUNCTIONS++++++++
  peasyVectors(); //function to get PVector info for position and look at.
  
 
 calcLookLR(rcvLookLR);
 println("rcvLookLR = " + rcvLookLR);
 
}//end draw

//defining the functions for rotations around Y_Pole
void calcLookLR (float v) {
  lookLR = v;
  float amountLookLR = map(lookLR - pLookLR,-1,1, -2*PI,2*PI);
  pCam.rotateY (amountLookLR);
  println("amountLookLR = " + amountLookLR);
  pLookLR = lookLR;
  //return;
}

//+++++DEFINE FUNCTIONS FOR ROTATIONS around Z_Pole
void calcLookUP(float v) {  //receive from fucntion calling at end of draw
  
  
  
  
}





void peasyVectors() {
  float[] pCamPosition; 
  float[] pCamLookAt;
  pCamPosition = pCam.getPosition(); 
  pCamLookAt = pCam.getLookAt(); 
  PVector pCamPos = new PVector(pCamPosition[0], pCamPosition[1], pCamPosition[2]);
  PVector pCamLook = new PVector(pCamLookAt[0], pCamLookAt[1], pCamLookAt[2]);
  print("pCamPos = " + pCamPos.x + " " + pCamPos.y + " " + pCamPos.z);
  println(" pCamLook = " + pCamLook.x +" " + pCamLook.y +" " + pCamLook.z);
}


//Shiffman's advice for starting full screen undecorated windows in second monitor
//void init() { 
//  frame.removeNotify();
//  frame.setUndecorated(true);
//  frame.addNotify();
//  super.init();
//}
//then in draw add:  frame.setLocation(0,0); // to place an undecorated screen at origin
//or in the case of second monitor (1024, 0) if my primary screen is (1024,768)

