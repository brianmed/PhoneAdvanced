<?php
 
include "twilio_php/Services/Twilio/Capability.php";
 
$accountSid = "ACf7254cdf525487b7d17bd3c698ed5416";
$authToken = "6b7dbb53a500cc820fdc909c183793a9";
 
// The app outgoing connections will use:
$appSid = "AP6da6a31e308bf27f11e69e7c6d5a1e12";
 
// The client name for incoming connections:
$clientName = "4794399010";
 
$capability = new Services_Twilio_Capability($accountSid, $authToken);
 
// This allows incoming connections as $clientName:
$capability->allowClientIncoming($clientName);
 
// This allows outgoing connections to $appSid with the "From"
// parameter being the value of $clientName
$capability->allowClientOutgoing($appSid, array(), $clientName);
 
// This returns a token to use with Twilio based on
// the account and capabilities defined above
$token = $capability->generateToken();
echo $token;
 
?>
