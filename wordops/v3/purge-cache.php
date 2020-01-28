<?php
    // CODE SOURCE:
    //https://stackoverflow.com/questions/56075107/purging-cloudflare-cache-through-their-api-in-php/56075108#56075108

    //Credentials for Cloudflare
    $cust_email = ''; //user@domain.tld
    $cust_xauth = ''; //retrieved from the backend after loggin in
    $cust_domain = $argv[1]; //domain.tld, the domain you want to control

    if($cust_email==""||$cust_xauth==""||$cust_domain=="") return;

    //Get the Zone-ID from Cloudflare since they don't provide that in the Backend
    $ch_query = curl_init();
    curl_setopt($ch_query, CURLOPT_URL, "https://api.cloudflare.com/client/v4/zones?name=".$cust_domain."&status=active&page=1&per_page=5&order=status&direction=desc&match=all");
    curl_setopt($ch_query, CURLOPT_RETURNTRANSFER, 1);
    $qheaders = array(
        'X-Auth-Email: ' . $cust_email,
        'X-Auth-Key: ' . $cust_xauth,
        'Content-Type: application/json'
    );

    // Lots of good info in here
    // var_dump($qheaders);
    curl_setopt($ch_query, CURLOPT_HTTPHEADER, $qheaders);
    $qresult = json_decode(curl_exec($ch_query),true);
    curl_close($ch_query);

    $cust_zone = $qresult['result'][0]['id'];

    //Purge the entire cache via API
    $ch_purge = curl_init();
    curl_setopt($ch_purge, CURLOPT_URL, "https://api.cloudflare.com/client/v4/zones/".$cust_zone."/purge_cache");
    curl_setopt($ch_purge, CURLOPT_CUSTOMREQUEST, "DELETE");
    curl_setopt($ch_purge, CURLOPT_RETURNTRANSFER, 1);
    $headers = [
        'X-Auth-Email: '.$cust_email,
        'X-Auth-Key: '.$cust_xauth,
        'Content-Type: application/json'
    ];
    $data = json_encode(array("purge_everything" => true));
    curl_setopt($ch_purge, CURLOPT_POST, true);
    curl_setopt($ch_purge, CURLOPT_POSTFIELDS, $data);
    curl_setopt($ch_purge, CURLOPT_HTTPHEADER, $headers);

    $result = json_decode(curl_exec($ch_purge),true);
    curl_close($ch_purge);

    //Tell the user if it worked
    if($result['success']==1) echo "Cloudflare Cache successfully purged! Changes should be visible right away.<br>If not try clearing your Browser Cache by pressing \"Ctrl+F5\"";
    else echo "Error purging Cloudflare Cache. Please log into Cloudflare and purge manually!";

?>
