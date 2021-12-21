
### step
* さしあたりqemuでbootできるようにする
  * ほぼコピーだけど、bootloaderの起動に成功した.


* 12/16
  * アセンブリ疑似命令
    * なんかlinker scriptに近しいものを感じた
  * a20 lineちゃんと調べたらちょっと分かった
  * plファイルがなぜが必要
  * asmマクロ
  * 486本読んで、セグメントに関する復讐をした
    * xv6と486本がかぶる部分多すぎて参考に鳴りまくった
  * リアルモード -> protect modeの移行を掴んだ

* 12/18
  * 今日はbootmainの実装をする.
    * readsecのことを調べてみたけど、すぐには理解できなそう...
      * diskから読んでくる部分で、この辺りはセクタの例のblogを読んだおかげで結構スッキリ読み進められる

* 12/21
  * kernelをloadできるようにする
  * 手順
    * bootセクタの後ろにkernelを置くように、起動imageを変更する
      * qemuで起動する際に、どうしてminikernel.imgが起動imgとして認識されている？
    * kernelのbinaryを生成する
      * elfのentry周りだけで小さく試す.
      * とりあえず、qemu上に何か表示したい。。
      * [ここ](https://wiki.osdev.org/Kernel_Debugging#Using_the_serial_port)を参考にserial通信を試みたけど、serial.logに表示されなかった

* 12/23
  * https://www.cse.iitd.ernet.in/~sbansal/os/previous_years/2014/lec/l3-hw1.html をみつつxv6とgdbの繋ぎをやる
    * そもそもentryまで到達してないから、そっちが先かも
  * 目標: debuggerを繋ぎ込んで、mainに処理が入ってるのが見えるようにする
  * 結果: 一応kernelmain.cのmain()には処理が届いてたみたいw

