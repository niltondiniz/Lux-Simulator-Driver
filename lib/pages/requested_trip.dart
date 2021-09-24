import 'dart:convert';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:driver/data/data.dart';
import 'package:driver/widgets/action_button_widget.dart';
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart';

import '../vars.dart';

class RequestedTripPage extends StatefulWidget {
  const RequestedTripPage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<RequestedTripPage> createState() => _RequestedTripPageState();
}

class _RequestedTripPageState extends State<RequestedTripPage> {
  Future<List<dynamic>> getTripPreview() async {
    setState(() {
      isLoading = true;
    });

    var timestamp = DateTime.now().millisecondsSinceEpoch;
    print(timestamp);

    payload['TRIPID'] = 123456;
    payload['LATFROM'] = -22.11106786437069;
    payload['LONFROM'] = -43.19338309603009;
    payload['LATTO'] = -22.524994596150663;
    payload['LONTO'] = -43.17142679715537;
    payload['PASSENGERNAME'] = 'passengerName.text';
    payload['STATUS'] = 'TRIP_PREVIEW_REQUESTED';

    var result = await dio.post('/trip-preview', data: payload);

    return result.data;
  }

  Future<List<dynamic>> acceptTrip() async {
    setState(() {
      isLoading = true;
      incomingTrip = false;
      acceptedTrip = true;
    });

    channelAwaitingTrip.emit(
        'driver-answer', {'TRIPID': data!['TRIPID'], 'DRIVERANSWER': true});
    channelAwaitingTrip.close();

    data!['DRIVERNAME'] = driverName.text;
    data!['DRIVERID'] = int.parse(driverId.text);
    data!['EVENTNAME'] = 'ACCEPT_TRIP';
    data!['ORIGIN'] = 'DRIVER';
    data!['STATUS'] = 'ENROUTE_TO_PASSENGER';
    data!['DRIVERIMAGEPROFILEURL'] =
        'https://i.ytimg.com/vi/ImRZowvFApM/maxresdefault.jpg';

    var result = await dio.post('/accept-trip', data: data);
    return result.data;
  }

  rejectTrip() {
    setState(() {
      isLoading = true;
    });

    dio.post('/reject-trip', data: data);
  }

  awaitingTrip() {
    setState(() {
      isLoading = true;
    });

    data!['EVENTNAME'] = 'AWAITING_TRIP';
    data!['ORIGIN'] = 'DRIVER';
    data!['STATUS'] = 'AWAITING_TRIP';

    dio.post('/awaiting-trip', data: data);
  }

  startTrip() {
    setState(() {
      isLoading = true;
    });

    data!['EVENTNAME'] = 'START_TRIP';
    data!['ORIGIN'] = 'DRIVER';
    data!['STATUS'] = 'MANNED';

    dio.post('/start-trip', data: data);
  }

  cancelTrip() {
    setState(() {
      isLoading = true;
    });

    data!['EVENTNAME'] = 'CANCEL_TRIP';
    data!['ORIGIN'] = 'DRIVER';
    data!['STATUS'] = 'WANDERING';

    dio.post('/driver-cancel-trip', data: data);
  }

  finishTrip() {
    setState(() {
      isLoading = true;
    });

    data!['EVENTNAME'] = 'FINISH_TRIP';
    data!['ORIGIN'] = 'DRIVER';
    data!['STATUS'] = 'WANDERING';

    dio.post('/finish-trip', data: data);
  }

  driverPosition() {
    data!['EVENTNAME'] = 'DRIVER_POSITION';
    data!['ORIGIN'] = 'DRIVER';
    data!['STATUS'] = 'WANDERING';
    data!['DRIVERNAME'] = 'NOME ZUADO';
    data!['DRIVERLAT'] = lat.text;
    data!['DRIVERLON'] = lon.text;
    data!['DRIVERID'] = int.parse(driverId.text);

    dio.post('/driver-position', data: data);
  }

  void listenTripIdRoom(String tripId) {
    channelTrip.on('trips_$tripId', (message) {
      setState(() {
        data = jsonDecode(message);
        distancia = (data!['DISTANCEM'] / 1000 as double).toStringAsFixed(2);
        duracao = (data!['DURATION'] / 60 as double).toStringAsFixed(2);
        valorEstimado = data!['ESTIMATEDPRICE'].toString();
        valorGanho = data!['DRIVEREARNING'].toString();
        status = data!['STATUS'] != null ? data!['STATUS'] : '[SEM VALOR]';
        motorista = data!['DRIVERNAME'] != null ? data!['DRIVERNAME'] : '';
        passageiro =
            data!['PASSENGERNAME'] != null ? data!['PASSENGERNAME'] : '';
        recibo = data!['URLRECEIPT'] != null ? data!['URLRECEIPT'] : '';
        isLoading = false;

        if (status == 'CREATED_RECEIPT' ||
            status == 'CANCELED' ||
            status == 'WANDERING') {
          channelTrip.close();
          channelTrip.destroy();
          connectToAwaitingTripWebSocket(driverId.text);
          incomingTrip = false;
          acceptedTrip = false;
        }
      });
    });
  }

  Future<bool> connectToTripWebSocket() async {
    bool connected = false;

    try {
      channelTrip = io('ws://stage.applux.com.br:3003', <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': false
      });

      channelTrip.connect();

      channelTrip.onConnect((_) {
        print('conectado');
        connected = true;
      });
      return connected;
    } catch (e) {
      print(e);
      return false;
    }
  }

  void connectToAwaitingTripWebSocket(String driverId) async {
    channelAwaitingTrip =
        io('ws://stage.applux.com.br:3042?id=$driverId', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false
    });

    print('Tentando conectar no websocket de motoristas disponivels');
    channelAwaitingTrip.connect();

    channelAwaitingTrip.onConnect((data) => print('Conectado!'));

    channelAwaitingTrip.on(driverId, (message) {
      setState(() {
        data = jsonDecode(message);

        //Abrir conexao do websocket de trip
        connectToTripWebSocket();
        listenTripIdRoom(data!['TRIPID'].toString());

        distancia = (data!['DISTANCEM'] / 1000 as double).toStringAsFixed(2);
        duracao = (data!['DURATION'] / 60 as double).toStringAsFixed(2);
        valorEstimado = data!['ESTIMATEDPRICE'].toString();
        valorGanho = data!['DRIVEREARNING'].toString();
        status = data!['STATUS'] != null ? data!['STATUS'] : '[SEM VALOR]';
        motorista = data!['DRIVERNAME'] != null ? data!['DRIVERNAME'] : '';
        passageiro =
            data!['PASSENGERNAME'] != null ? data!['PASSENGERNAME'] : '';
        isLoading = false;
        incomingTrip = true;
      });
    });
  }

  void resetAll() {
    setState(() {
      data = {};

      // try {
      //   channelAwaitingTrip.close();
      //   //channelAwaitingTrip.destroy();
      //   channelTrip.close();
      //   //channelTrip.destroy();
      // } catch (e) {}

      distancia = null;
      duracao = null;
      valorEstimado = null;
      valorGanho = null;
      status = null;
      motorista = null;
      passageiro = null;
      isLoading = false;
      incomingTrip = false;

      connectToAwaitingTripWebSocket(driverId.text);
    });
  }

  @override
  void initState() {
    super.initState();
    resetAll();
    driverId.text = Random().nextInt(100).toString();
    connectToAwaitingTripWebSocket(driverId.text);
  }

  @override
  Widget build(BuildContext context) {
    lat.text = '-22.11106786437069';
    lon.text = '-43.19338309603009';
    driverName.text = 'Motorista Simulador 1';

    return GestureDetector(
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          appBar: AppBar(
            title: Text(widget.title),
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 32),
              child: SizedBox(
                height: double.maxFinite,
                width: MediaQuery.of(context).size.width,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const Text(
                      "Dados do Motorista",
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    TextField(
                      keyboardType: TextInputType.name,
                      controller: driverId,
                      decoration: const InputDecoration(
                          hintText: "Informe ID do motorista"),
                    ),
                    TextField(
                      keyboardType: TextInputType.name,
                      controller: driverName,
                      decoration: const InputDecoration(
                          hintText: "Informe o nome do motorista"),
                    ),
                    const SizedBox(
                      height: 60,
                    ),
                    const Text(
                      "Localização atual",
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    TextField(
                      keyboardType: TextInputType.number,
                      controller: lat,
                      decoration: const InputDecoration(
                          hintText: "Informe a latitude atual"),
                    ),
                    TextField(
                      keyboardType: TextInputType.number,
                      controller: lon,
                      decoration: const InputDecoration(
                          hintText: "Informe a longitude atual"),
                    ),
                    const SizedBox(
                      height: 60,
                    ),
                    !isLoading
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                status != null
                                    ? 'Status da Corrida: $status'
                                    : '',
                                style: TextStyle(fontWeight: FontWeight.w800),
                              ),
                              Text(data!['TRIPID'] != null
                                  ? 'Trip Id: ${data!["TRIPID"]}'
                                  : ''),                              
                              Text(distancia != null
                                  ? 'Distância: $distancia Km'
                                  : ''),
                              Text(duracao != null
                                  ? 'Duração: $duracao minutos'
                                  : ''),
                              Text(valorEstimado != null
                                  ? 'Valor: R\$ $valorEstimado'
                                  : ''),
                              Text(valorGanho != null
                                  ? 'Valor Ganho: R\$ $valorGanho'
                                  : ''),
                              SizedBox(
                                height: 30,
                              ),
                              passageiro != null
                                  ? Text(
                                      "Dados do Passageiro",
                                      style: TextStyle(
                                          fontWeight: FontWeight.w800),
                                    )
                                  : Center(),
                              Text(passageiro != null
                                  ? 'Passageiro: $passageiro'
                                  : ''),
                              SizedBox(
                                height: 30,
                              ),
                              Text(
                                "Ações do Motorista",
                                style: TextStyle(fontWeight: FontWeight.w800),
                              ),
                              ActionButtonWidget(
                                  label: 'Enviar minha posição',
                                  action: () async {
                                    var result = await driverPosition();
                                    print(result);
                                  }),
                              incomingTrip
                                  ? ActionButtonWidget(
                                      label: 'Aceitar Corrida',
                                      action: () async {
                                        var result = await acceptTrip();
                                        print(result);
                                      })
                                  : Center(),
                              incomingTrip
                                  ? ActionButtonWidget(
                                      label: 'Recusar Corrida',
                                      action: () {
                                        rejectTrip();
                                      })
                                  : Center(),
                              acceptedTrip
                                  ? ActionButtonWidget(
                                      label: 'Chegou no Passageiro',
                                      action: () {
                                        awaitingTrip();
                                      })
                                  : Center(),
                              acceptedTrip
                                  ? ActionButtonWidget(
                                      label: 'Iniciar Corrida',
                                      action: () {
                                        startTrip();
                                      })
                                  : Center(),
                              acceptedTrip
                                  ? ActionButtonWidget(
                                      label: 'Cancelar Corrida',
                                      action: () {
                                        cancelTrip();
                                      })
                                  : Center(),
                              acceptedTrip
                                  ? ActionButtonWidget(
                                      label: 'Finalizar Corrida',
                                      action: () {
                                        finishTrip();
                                      })
                                  : Center(),
                              ActionButtonWidget(
                                  label: 'Nova Simulação',
                                  action: () {
                                    resetAll();
                                  }),
                            ],
                          )
                        : CircularProgressIndicator(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
