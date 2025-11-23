import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
import '../widgets/house/house_widget.dart';
import '../widgets/house/house_info_widget.dart';
import '../widgets/dialogs/success_dialog_widget.dart';
import '../widgets/custom_scaffold.dart';
import '../widgets/loading_widget.dart'; 
import '../main.dart';
import 'package:provider/provider.dart';
import '../providers/house_provider.dart';

class HomeScreen extends StatefulWidget {
  final bool showSuccessDialog;

  const HomeScreen({super.key, this.showSuccessDialog = false});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with RouteAware {
  final ApiService api = ApiService();
  bool isLoading = true;

  @override
  void initState() {
    super.initState();

     // 🔥 Cargar la casa inmediatamente cuando se entra al Home
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<HouseProvider>().load();
      }
    });

    if (widget.showSuccessDialog) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          builder: (context) => const SuccessDialogWidget(
            title: 'Inicio de sesión',
            message: 'Has iniciado sesión correctamente.',
            buttonText: 'Aceptar',
          ),
        );
      });
    }

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => isLoading = false);
    });
  }

  // 🔥 SUSCRIPCIÓN AL OBSERVADOR
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)! as PageRoute);
  }

  // 🔥 CUANDO EL USUARIO VUELVE A ESTA SCREEN → REFRESCAR CASA
  @override
  void didPopNext() {
    super.didPopNext();
    context.read<HouseProvider>().load();
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: CustomScaffold(
        title: 'Inicio',
        currentRoute: '/home',
        extendBody: true,
        extendBodyBehindAppBar: true,
        body: SizedBox.expand(
          child: Stack(
            children: [
              Transform.translate(
                offset: Offset(0, -MediaQuery.of(context).size.height * 0.06),
                child: const CasaWidget(),
              ),



              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        HomeInfoWidget(),
                      ],
                    ),
                  ),
                ),
              ),
              if (isLoading)
                const Positioned.fill(
                  child: LoadingWidget(message: "Cargando inicio..."),
                ),
            ],
          ),
        ),

      ),
    );
  }
}
