// let serverBaseUrl = "http://192.168.43.132:8080";
// let webClientBaseUrl = "http://192.168.43.132/consultationmanagementsystem/webclient";

let serverBaseUrl = "http://192.168.43.179:8080";
let webClientBaseUrl = "http://192.168.43.132/consultationmanagementsystem/webclient";

// let serverBaseUrl = "http://3.20.119.226:8080";
// let webClientBaseUrl = "http://3.20.119.226/cms/index.html";

var firebaseConfig = {
    apiKey: "AIzaSyCds45N0E52JbAH2JSiwyWCsqEwnOlxCP0",
    authDomain: "consultant-e6956.firebaseapp.com",
    databaseURL: "https://consultant-e6956.firebaseio.com",
    projectId: "consultant-e6956",
    storageBucket: "consultant-e6956.appspot.com",
    messagingSenderId: "1008185790163",
    appId: "1:1008185790163:web:8b0846089683685c654e26",
    measurementId: "G-YQXJFTNYTQ"
};

var consultant = firebase.initializeApp(firebaseConfig,"consultant");
console.log("database name = ",consultant.name); 
var db = consultant.firestore();