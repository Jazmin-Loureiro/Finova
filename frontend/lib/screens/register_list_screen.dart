import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/register.dart';
import 'package:intl/intl.dart'; // 👈 para formatear la fecha

class RegisterListScreen extends StatefulWidget {
  final int moneyMakerId;
  const RegisterListScreen({super.key, required this.moneyMakerId});

  @override
  State<RegisterListScreen> createState() => _RegisterListScreenState();
}

class _RegisterListScreenState extends State<RegisterListScreen> {
  final ApiService api = ApiService();
  bool isLoading = true;
  List<Register> registers = [];

  @override
  void initState() {
    super.initState();
    fetchRegisters();
  }

  Future<void> fetchRegisters() async {
  setState(() => isLoading = true);
  try {
    registers = await api.getRegistersByMoneyMaker(widget.moneyMakerId);
  } catch (e) {
    registers = [];
  } finally {
    setState(() => isLoading = false);
  }
}

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy'); // 👈 formato fecha

    return Scaffold(
      appBar: AppBar(title: const Text('Registros')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : registers.isEmpty
              ? const Center(child: Text('No hay registros para esta moneda'))
              : ListView.builder(
                  itemCount: registers.length,
                  itemBuilder: (context, index) {
                    final r = registers[index];
                    final tipo = r.type == "income" ? "Ingreso" : "Gasto";
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      child: ListTile(
                        leading: Icon(
                          r.type == "income"
                              ? Icons.arrow_downward
                              : Icons.arrow_upward,
                          color: r.type == "income"
                              ? Colors.green
                              : Colors.red,
                        ),
                        title: Text(r.name,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${tipo} - ${r.currency.code } ${r.currency.symbol} ${r.balance .toStringAsFixed(2)}'),
                        trailing: Text(dateFormat.format(r.created_at)),
                      ),
                    );
                  },
                ),
    );
  }
}
