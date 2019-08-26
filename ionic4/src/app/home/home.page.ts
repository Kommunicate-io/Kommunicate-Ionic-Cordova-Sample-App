import { Component } from '@angular/core';

@Component({
  selector: 'app-home',
  templateUrl: 'home.page.html',
  styleUrls: ['home.page.scss'],
})
export class HomePage {

  userId:string = '';
  password:string = '';

  login(){
    // Your app login API web service call triggers
    var kmUser = {
        'userId' : this.userId,   //Replace it with the userId of the logged in user
        'password' : this.password,  //Put password here
        'authenticationTypeId' : 1,
        'applicationId' : '22823b4a764f9944ad7913ddb3e43cae1',  //replace "applozic-sample-app" with Application Key from Applozic Dashboard
        'deviceApnsType' : 0    //Set 0 for Development and 1 for Distribution (Release)
    };

    kommunicate.login(kmUser, function(response) {
      console.log("Kommunicate login success response : " + response);
      kommunicate.registerPushNotification((response)=>{
        console.log("Kommunicate Push success response : " + response);
      },()=>{
        console.log("Kommunicate Push failed response : " + response);
      });
      //  kommunicate.launchConversation(function(response) {
      //    console.log("Kommunicate launch success response : " + response);
      //  }, function(response) {
      //   console.log("Kommunicate launch failure response : " + response);
      //  });
      let convInfo = {
        'agentIds': ['reytum@live.com'],
        'botIds': ['Hotel-Booking-Assistant']  //list of botIds
       };
       
    kommunicate.startNewConversation(convInfo, (response) => {
        //You can launch the particular conversation here, response will be the clientChannelKey
         let convObj = {
          'clientChannelKey' : response, //pass the clientChannelKey here
          'takeOrder' : true //skip chat list on back press, pass false if you want to show chat list on back press
        };
        
        kommunicate.launchParticularConversation(convObj, function(response) {
          //Conversation launched successfully
        }, function(response) {
          //Conversation launch failed
        });
      },(response) => {
      });
    }, function(response) {
      console.log("Kommunicate login failure response : " + response);
    });
  }
}

declare var kommunicate: any;
