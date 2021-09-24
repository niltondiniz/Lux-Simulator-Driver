import 'dart:convert';

import 'package:driver/data/data.dart';
import 'package:driver/widgets/action_button_widget.dart';
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart';

import '../vars.dart';

class FreeRoutePage extends StatefulWidget {
  const FreeRoutePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _FreeRoutePageState createState() => _FreeRoutePageState();
}

class _FreeRoutePageState extends State<FreeRoutePage> {
  startTrip() async {
    String _tripId = '998';
    listenTripIdRoom(_tripId);

    setState(() {
      isLoading = true;
    });

    data = payload;
    data!['TRIPID'] = _tripId;
    data!['EVENTNAME'] = 'START_TRIP';
    data!['ORIGIN'] = 'DRIVER';
    data!['STATUS'] = 'MANNED';
    data!['PASSENGERPHONE'] = passengerPhone.text;
    data!['ESTIMATEDPRICE'] = estimatedPrice.text;
    data!['TRIPTYPE'] = 'FREE_ROUTE';
    data!['DRIVEREARNING'] = estimatedPrice.text;

    dio.post('/start-trip', data: data);
  }

  cancelTrip() {
    setState(() {
      isLoading = true;
    });

    String _tripId = '998';
    data!['TRIPID'] = _tripId;
    data!['EVENTNAME'] = 'CANCEL_TRIP';
    data!['ORIGIN'] = 'DRIVER';
    data!['STATUS'] = 'WANDERING';
    data!['TRIPTYPE'] = 'FREE_ROUTE';

    dio.post('/driver-cancel-trip', data: data);
  }

  finishTrip() {
    setState(() {
      isLoading = true;
    });

    String _tripId = '998';
    data!['TRIPID'] = _tripId;
    data!['EVENTNAME'] = 'FINISH_TRIP';
    data!['ORIGIN'] = 'DRIVER';
    data!['STATUS'] = 'WANDERING';
    data!['TRIPTYPE'] = 'FREE_ROUTE';

    dio.post('/finish-trip', data: data);
  }

  driverPosition() {
    data!['EVENTNAME'] = 'DRIVER_POSITION';
    data!['ORIGIN'] = 'DRIVER';
    data!['STATUS'] = 'WANDERING';
    data!['DRIVERNAME'] = 'NOME ZUADO';
    data!['DRIVERLAT'] = -22.11106786437069;
    data!['DRIVERLON'] = -43.19338309603009;
    data!['DRIVERID'] = 7;

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
        telefonePassageiro =
            data!['PASSENGERPHONE'] != null ? data!['PASSENGERPHONE'] : '';
        isLoading = false;

        // if (status == 'CREATED_RECEIPT' ||
        //     status == 'CANCELED' ||
        //     status == 'WANDERING') {
        //   channelTrip.close();
        //   channelTrip.destroy();
        //   //connectToAwaitingTripWebSocket();
        //   incomingTrip = false;
        //   acceptedTrip = false;
        // }
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

  void resetAll() {
    setState(() {
      data = {};

      // try {
      //   channelTrip.close();        
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

      connectToTripWebSocket();
    });
  }

  @override
  void initState() {
    super.initState();
    resetAll();
    connectToTripWebSocket();
  }

  @override
  Widget build(BuildContext context) {
    lat.text = '-22.11106786437069';
    lon.text = '-43.19338309603009';
    driverName.text = 'Motorista Simulador 1';
    passengerPhone.text = '5524981411827';
    estimatedPrice.text = '50';

    incomingTrip = true;

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
                    const Text(
                      "Dados da Corrida",
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    TextField(
                      keyboardType: TextInputType.number,
                      controller: passengerPhone,
                      decoration: const InputDecoration(
                          hintText: "Informe o Telefone do Passageiro"),
                    ),
                    TextField(
                      keyboardType: TextInputType.number,
                      controller: estimatedPrice,
                      decoration: const InputDecoration(
                          hintText: "Informe o Valor da Corrida"),
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
                              Text(telefonePassageiro != null
                                  ? 'Telefone do Passageiro: $telefonePassageiro'
                                  : ''),
                              SizedBox(
                                height: 30,
                              ),
                              Text(
                                "Ações do Motorista",
                                style: TextStyle(fontWeight: FontWeight.w800),
                              ),
                              ActionButtonWidget(
                                  label: 'Iniciar Corrida',
                                  action: () {
                                    startTrip();
                                  }),
                              ActionButtonWidget(
                                  label: 'Cancelar Corrida',
                                  action: () {
                                    cancelTrip();
                                  }),
                              ActionButtonWidget(
                                  label: 'Finalizar Corrida',
                                  action: () {
                                    finishTrip();
                                  }),
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
