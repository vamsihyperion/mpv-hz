function sleep(delay) {
  var start = (new Date()).getTime();
  while ((new Date()).getTime() - start < delay) {
    continue;
  }
}

function takeSsS() {

    var N = 8;
    var C = 0;
    var start = 5;
    var end = 95;
    var step = (end - start)/(N+1);
    var percent = start += step;

    while (C < N) {
        mp.commandv("sync","seek", percent, "absolute-percent");
        mp.msg.info((C+1)+"/"+N);
        sleep(1000);
        mp.commandv("sync","screenshot","video");
        percent+=step;
        C++;
    }
    mp.commandv("quit",0);
}


mp.register_event("file-loaded", takeSsS)