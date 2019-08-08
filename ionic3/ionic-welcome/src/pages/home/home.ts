import { Component } from '@angular/core';
import { NavController, App } from 'ionic-angular';
import {Platform} from 'ionic-angular';


@Component({
  selector: 'page-home',
  templateUrl: 'home.html'
})
export class HomePage {

  constructor(public navCtrl: NavController, public app: App, platform: Platform) {
    (function(d, m){
      var kommunicateSettings = {"appId":"22823b4a764f9944ad7913ddb3e43cae1","conversationTitle":"Rey-TUM","popupWidget":true,"automaticChatOpenOnNavigation":true};
      var s = document.createElement("script"); s.type = "text/javascript"; s.async = true;
      s.src = "https://widget.kommunicate.io/v2/kommunicate.app";
      var h = document.getElementsByTagName("head")[0]; h.appendChild(s);
      window.kommunicate = m; m._globals = kommunicateSettings;
    })(document, window.kommunicate || {});
    platform.ready().then(() => {

    });

  }

  logout(){
    //Api Token Logout
    const root = this.app.getRootNav();
    root.popToRoot();
  }

}

declare var window: any;
declare var document: any;

