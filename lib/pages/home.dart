import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io';

import 'package:provider/provider.dart';
import 'package:pie_chart/pie_chart.dart';

import 'package:band_names/models/band.dart';
import 'package:band_names/providers/socket_service.dart';

class HomePage extends StatefulWidget {

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  List<Band> bands = [
    // Band(id:'1', name: 'Metallica', votes: 5),
    // Band(id:'2', name: 'Queen', votes: 5),
    // Band(id:'3', name: 'Heroes del Silencio', votes: 5),
    // Band(id:'4', name: 'Bon Jovi', votes: 5),
  ];

  @override
  void initState() {
    final socketService = Provider.of<SocketService>(context,listen: false);

    socketService.socket.on('active-bands', _handleActiveBands);

    super.initState();
  }

  _handleActiveBands(dynamic data){
    this.bands= (data as List)
      .map((band) => Band.fromMap(band)).toList();

    setState(() {});
  }

  @override
  void dispose() { 
    final socketService = Provider.of<SocketService>(context,listen: false);
    socketService.socket.off('active-bands');
    super.dispose();
  }

  
  @override
  Widget build(BuildContext context) {
    final socketService = Provider.of<SocketService>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text("BandNames", style: TextStyle(color: Colors.black87),),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: <Widget>[
          Container(
            margin: EdgeInsets.only(right: 10),
            child: (socketService.serverStatus==ServerStatus.Online)
            ?Icon(Icons.check_circle,color:Colors.blue[300])
            :Icon(Icons.offline_bolt,color:Colors.red)
          )
        ],
      ),
      body: Column(
        children: [
          _showGraph(),
          Expanded(
            child: ListView.builder(
              itemCount: bands.length,
              itemBuilder: (BuildContext context, int idx) => _bandTile(bands[idx])
             
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        elevation: 1,
        onPressed: addNewBand
      ),
    );
  }

  Widget _bandTile(Band band) {
    final socketService = Provider.of<SocketService>(context,listen: false);
    return Dismissible(
      key: Key(band.id),
      direction: DismissDirection.startToEnd,
      onDismissed: (_) => socketService.socket.emit('delete-band',{'id':band.id})
      ,
      background: Container(
        padding: EdgeInsets.only(left:8.0),
        color:Colors.red,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text('Delete Band',style: TextStyle(color: Colors.white),)),
      ),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(band.name.substring(0,2)),
          backgroundColor: Colors.blue[100],
        ),
        title: Text(band.name),
        trailing: Text("${band.votes}", style: TextStyle(fontSize: 20)),
        onTap: ()=> socketService.socket.emit('vote-band',{"id":band.id})
        
      ),
    );
  }

  void addNewBand(){
    final textController = TextEditingController();

    if(Platform.isIOS){
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('New band name:'),
          content: TextField(
            controller: textController,
          ),
          actions: <Widget>[
            MaterialButton(
              child: Text('Add'),
              elevation: 5,
              textColor: Colors.blue,
              onPressed: ()=> addBandtoList(textController.text)
            )
          ],
        )
      
      );
    }

    showCupertinoDialog(
      context: context, 
      builder: (_) => CupertinoAlertDialog(
        title: Text('New band name'),
        content: CupertinoTextField(
          controller: textController,
        ),
        actions: <Widget>[
          CupertinoDialogAction(
            child: Text('Add'),
            onPressed: () => addBandtoList(textController.text),              
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: Text('Dismiss'),
            onPressed: () => Navigator.pop(context),              
          ),
        ],
      )
    );
    
  }

  void addBandtoList(String name){
    final socketService = Provider.of<SocketService>(context,listen:false);
    if(name.length>1){
      
      socketService.socket.emit('add-band',{'name':name});

    }

    Navigator.pop(context);

  }

  Widget _showGraph() {
    Map<String, double> dataMap = new Map();
    dataMap.putIfAbsent("Flutter", () => 5);
    bands.forEach((band) { 
      dataMap.putIfAbsent(band.name, () => band.votes.toDouble());

    });

    final List<Color> colorList = [
      Colors.blue,
      Colors.purple,
      Colors.pink,
      Colors.green,
      Colors.yellow
    ];

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: PieChart(
          dataMap: dataMap,
          animationDuration: Duration(milliseconds: 800),
          chartLegendSpacing: 32.0,
          chartRadius: MediaQuery.of(context).size.width / 2.7,
          showChartValuesInPercentage: true,
          showChartValues: true,
          showChartValuesOutside: false,
          chartValueBackgroundColor: Colors.grey[200],
          colorList: colorList,
          showLegends: true,
          legendPosition: LegendPosition.right,
          decimalPlaces: 1,
          showChartValueLabel: true,
          initialAngle: 0,
          chartValueStyle: defaultChartValueStyle.copyWith(
            color: Colors.blueGrey[900].withOpacity(0.9),
          ),
          chartType: ChartType.ring,
      ),
    ) ;
  }


  
}