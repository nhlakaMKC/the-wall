import 'package:cloud_firestore/cloud_firestore.dart';

String formatDate(Timestamp timestamp) {
  //we are reteiving time from firebsae
  //convert time to string
  DateTime dateTime = timestamp.toDate();

  //get the year
  String year = dateTime.year.toString();

  //get the month
  String month = dateTime.month.toString();

  //get the day
  String day = dateTime.day.toString();

  //get the time
  String hour = dateTime.hour.toString();
  String minute = dateTime.minute.toString();

  //final formated sate 

  String formatedDate = "$hour:$minute $day/$month/$year";
  return formatedDate;
}
