/*
This sketch fetches a number of keywords from a URL in JSON format and visualises them in a wave-shaped tag-cloud.
The URL returns a number of ordered keywords as a JSONArray. The closer a keyword appears to the top of the array the 
bigger its font-size and relative position towards the upper left corner of the display. Keywords towards the end 
of the array appear in smaller font-size and more towards the bottom-right corner of the display.

written by Mark Bilandzic, 15 November, 2012

Source code based on
- http://wordcram.org/ (https://github.com/danbernier/WordCram)
- http://wiki.processing.org/w/Threading

*/


import wordcram.*;
import org.json.*;

WordCram wordCram;

String baseURL = "http://theedge.checkinsystem.net/API/view_list_distinctusercheckins_all.php";

String filter_word = "allinone";
String title = "";
String subtitle = "";
String title_help = "Can you Help";
String subtitle_help = "co-present users with these topics?";
String title_interests = "Interests";
String subtitle_interests = "of co-present users at The Edge";
String title_skills = "Skills";
String subtitle_skills = "of co-present users at The Edge";
String title_allinone = "Who is here?";
String subtitle_allinone = "...and knows/needs/does what?";

PImage cachedImage; // Cache the rendered wordcram, so drawing is fast
//JSONArray checkins;
Word[] wordArray = new Word[] { };
Word lastClickedWord; // The word that was under the user's last click
String userDetails = "";

SimpleThread_fetchWords simpleThread_fetchWords;

color background_color = color(20, 20, 30);
color title_color = color(100,100,100);

color help_colour = color(255,0,0);
color skills_colour = color(98,255,0);
color interests_colour = color(250, 250, 250);
       
      
JSONArray checkins;
JSONObject checkin;
JSONArray keywords_help;
JSONArray keywords_skills;
JSONArray keywords_categories;
Word w;


void setup() {
//  size(screen.width, screen.height);
  size(displayWidth, displayHeight);
  background(background_color);
  int threadwaittime = 5000; //ms before each DB-fetch    
  
  simpleThread_fetchWords = new SimpleThread_fetchWords(threadwaittime,"fetchWords", this);
  simpleThread_fetchWords.start();  
    
}

void draw() {
  
  if (cachedImage != null){
    image(cachedImage, 0, 0);
    g.removeCache(cachedImage); 
  }

  //DRAW LAST CLICKED WORD
  // If the user's last click was on a word, render it big and blue:
  if (lastClickedWord != null) {
    noStroke();
    
    pushMatrix();
        
          translate(200, height/2 - textAscent());
            fill(250, 230);
            rect(0, 0, width, textAscent() + height/3);
    
          String typeofcall = "";
            if((String)lastClickedWord.getProperty("filterword") == "help") typeofcall = "needs help with";
            else if((String)lastClickedWord.getProperty("filterword") == "skills") typeofcall = "is happy to share skills in";   
            else if((String)lastClickedWord.getProperty("filterword") == "categories") typeofcall = "is interested in";   
        
          userDetails = 
            (String)lastClickedWord.getProperty("name") + "\n" +
            "[" + (String)lastClickedWord.getProperty("aboutme") + "]\n" +
            typeofcall + ": " + (String)lastClickedWord.word + "\n" +
            //(String)lastClickedWord.getProperty("status") + "\n" +
            "location: " + (String)lastClickedWord.getProperty("sublocation") + ", " +
            (String)lastClickedWord.getProperty("checkintime");
        
          textFont(loadFont("Helvetica-Bold-30.vlw"));
          fill(30, 144, 13, 150);
          textAlign(LEFT);
          smooth();
          textLeading(30);  // Set leading to 10
          text(userDetails, 20, 20+ textAscent());

     popMatrix();
  }
  
  //DRAW CAPTION
    fill (title_color);
    textFont(loadFont("Helvetica-Bold-150.vlw"));
    textAlign(RIGHT);
    smooth();
    
    if (filter_word == "help"){
      title = title_help;
      subtitle = subtitle_help;
    }
    else if (filter_word == "skills"){
      title = title_skills;
      subtitle = subtitle_skills;
    }
    else if (filter_word == "categories"){
      title = title_interests;
      subtitle = subtitle_interests;
    }
    else if (filter_word == "allinone"){
      title = title_allinone;
      subtitle = subtitle_allinone;
    }
    
    text (title, displayWidth, 100); 

    fill (title_color);
    textFont(createFont("sans", 50));
    textAlign(RIGHT);
    smooth();
    text (subtitle, displayWidth, 150); 
    
    
    //DRAW LEGEND

    textFont(loadFont("Helvetica-Bold-20.vlw"));
    textAlign(LEFT);
    smooth();
      
    int rect_size = 50;
    int rect_gap = 80;

    pushMatrix();
      translate(0, height - 250);
        fill(help_colour);
        rect(0, 0, rect_size, rect_size);  // White rectangle
        fill (title_color);
        text ("users seek help with", 0, 0);
      
      translate(0, rect_gap);
        fill(skills_colour);  
        rect(0, 0, rect_size, rect_size);  // Black rectangle
        fill (title_color);
        text ("users can share skills in", 0, 0);
        
      translate(0, rect_gap);
        fill(interests_colour);  
        rect(0, 0, rect_size, rect_size);  // Black rectangle
        fill (title_color);
        text ("users interested in", 0, 0);
        
//      translate(0, rect_gap);
//        fill(checkin_morethantwodays);  
//        rect(0, 0, rect_size, rect_size);  // Black rectangle
//        fill (title_color);
//        text ("long gone", 0, 0);
        
    popMatrix();
}


void mouseClicked() {
  lastClickedWord = wordCram.getWordAt(mouseX, mouseY);
  println(lastClickedWord);
}


class SimpleThread_fetchWords extends Thread {
 
  boolean running;           // Is the thread running?  Yes or no?
  int wait;                  // How many milliseconds should we wait in between executions?
  String id;                 // Thread name
  int count;                 // counter
  processing.core.PApplet applet;
   
  SimpleThread_fetchWords (int w, String s, processing.core.PApplet applet) {
    wait = w;
    running = false;
    id = s;
    count = 0;
    this.applet = applet;
  }
 
  int getCount() {
    return count;
  }
 
  void start () {
    running = true;
    // Print messages
    println("Starting thread (will execute every " + wait + " milliseconds.)"); 
    // Do whatever start does in Thread, don't forget this!
    super.start();
  }
 
  // We must implement run, this gets triggered by start()
  void run () {
    while (running) {
      println(id + " - thread loop number: " + count);
      count++;
      
      getUserData(baseURL);

          for (int k = 0 ; k < wordArray.length ; k++){
            w = wordArray[k];
            if ((((Integer)w.getProperty("hours_since_checkin") < 2)) && ((String) w.getProperty("filterword") == "help")) w.setColor(help_colour);
            else if ((((Integer)w.getProperty("hours_since_checkin") < 8)) && ((String) w.getProperty("filterword") == "help")) w.setColor(help_colour);
            else if ((((Integer)w.getProperty("hours_since_checkin") <= 48)) && ((String) w.getProperty("filterword") == "help")) w.setColor(help_colour);
            else if ((((Integer)w.getProperty("hours_since_checkin")  > 48)) && ((String) w.getProperty("filterword") == "help")) w.setColor(help_colour);

            else if ((((Integer)w.getProperty("hours_since_checkin") < 2)) && ((String) w.getProperty("filterword") == "skills")) w.setColor(skills_colour);
            else if ((((Integer)w.getProperty("hours_since_checkin") < 8)) && ((String) w.getProperty("filterword") == "skills")) w.setColor(skills_colour);
            else if ((((Integer)w.getProperty("hours_since_checkin") <= 48)) && ((String) w.getProperty("filterword") == "skills")) w.setColor(skills_colour);
            else if ((((Integer)w.getProperty("hours_since_checkin")  > 48)) && ((String) w.getProperty("filterword") == "skills")) w.setColor(skills_colour);

            else w.setColor(interests_colour);
//            else w.setColor(checkin_morethantwodays);


          }        

          wordCram = new WordCram(applet)
          .fromWords(wordArray)
//          .withColor(#ededed)
      //    .withPlacer(Placers.horizLine())
          .withPlacer(Placers.wave())
          .sizedByRank(8, 35);
        
          noLoop();
            background(background_color);
            wordCram.drawAll();
            cachedImage = get();
            wordArray = new Word[] { }; //clear word-array to refresh
          loop();  
        
        try {
          sleep((long)(wait));
        } catch (Exception e) {
        }
    }
    System.out.println(id + " thread is done!");  // The thread is done when we get to the end of run()
  }
 
 
  // Our method that quits the thread
  void quit() {
    System.out.println("Quitting."); 
    running = false;  // Setting running to false ends the loop in run()
    // IUn case the thread is waiting. . .
    interrupt();
  }

  void getUserData(String url){                
      // parse JSON
      String result = processing.core.PApplet.join(loadStrings( url ), "");
      try {
        checkins = new JSONArray(result);
        int checkins_length = checkins.length();
        println("number of users " + checkins_length);
        
        for (int i = 0; i < checkins_length; i++){
          checkin = checkins.getJSONObject(i);
          
          String user_id = checkin.getString("user_id");
          String firstname = checkin.getString("firstname");
          String lastname = checkin.getString("lastname");
          String timepassed = "";
          int months_since_checkin = checkin.getInt("months_since_checkin");
          int days_since_checkin = checkin.getInt("days_since_checkin");
          int hours_since_checkin = checkin.getInt("hours_since_checkin");
          int minutes_since_checkin = checkin.getInt("minutes_since_checkin");
          
          if(months_since_checkin > 0) timepassed = months_since_checkin + " months";
          else if(days_since_checkin > 0) timepassed = days_since_checkin + " days";
          else if(hours_since_checkin > 0) timepassed = hours_since_checkin + " hours";
          else if(minutes_since_checkin >= 0) timepassed = minutes_since_checkin + " minutes";
          
          String sublocation = checkin.getString("sublocation");
          String mainlocation = checkin.getString("mainlocation");
          String skills = checkin.getString("skills");
          String interests = checkin.getString("categories");
          String help = checkin.getString("help");
          String userstatus = checkin.getString("status");
          String aboutme = checkin.getString("aboutme");

          keywords_help = checkin.getJSONArray("help");           
          for (int j = 0; j < keywords_help.length(); j++){
            Word temp = new Word(keywords_help.getString(j), 1);
              temp.setProperty("name", firstname + " " + lastname);
              temp.setProperty("sublocation", sublocation);
              //temp.setProperty("status", "happy to chat");
              temp.setProperty("aboutme", aboutme);
              temp.setProperty("checkintime", timepassed + " ago");
              temp.setProperty("hours_since_checkin", hours_since_checkin);
              temp.setProperty("filterword", "help");
              wordArray = (Word[])append(wordArray, temp);
          }
          
          keywords_skills = checkin.getJSONArray("skills");           
          for (int j = 0; j < keywords_skills.length(); j++){
            Word temp = new Word(keywords_skills.getString(j), 1);
              temp.setProperty("name", firstname + " " + lastname);
              temp.setProperty("sublocation", sublocation);
              //temp.setProperty("status", "happy to chat");
              temp.setProperty("aboutme", aboutme);
              temp.setProperty("checkintime", timepassed + " ago");
              temp.setProperty("hours_since_checkin", hours_since_checkin);
              temp.setProperty("filterword", "skills");
              wordArray = (Word[])append(wordArray, temp);
          }
          
          keywords_categories = checkin.getJSONArray("categories");           
          for (int j = 0; j < keywords_categories.length(); j++){
            Word temp = new Word(keywords_categories.getString(j), 1);
              temp.setProperty("name", firstname + " " + lastname);
              temp.setProperty("sublocation", sublocation);
              //temp.setProperty("status", "happy to chat");
              temp.setProperty("aboutme", aboutme);
              temp.setProperty("checkintime", timepassed + " ago");
              temp.setProperty("hours_since_checkin", hours_since_checkin);
              temp.setProperty("filterword", "categories");
              wordArray = (Word[])append(wordArray, temp);
          }
          
    
         }
      } catch (JSONException e) 
      {
        println ("There was an error parsing the JSONObject:" + e);
      }

  }


}

