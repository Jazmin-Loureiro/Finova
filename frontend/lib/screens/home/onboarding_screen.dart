import 'package:flutter/material.dart';
import 'package:frontend/screens/login_screen.dart';
import 'package:animate_do/animate_do.dart';
import 'package:frontend/screens/register_screen.dart';
import 'package:lottie/lottie.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int currentPage = 0;

  final List<Map<String, dynamic>> onboardingData = [
    {
      "title": "Finanzas Simples",
      "subtitle":
           "Lleva el control de todos tus ingresos y gastos desde un solo lugar. Organiza tus fuentes de dinero y simplifica tu gestión diaria.",
      "widget": Lottie.asset(
        'assets/lottie/BudgetAndBills.json',
        height: 300,
        fit: BoxFit.contain,
      ),
    },
    {
      "title": "Ahorros Inteligentes",
      "subtitle":
          "Alcanza tus metas más rápido creando objetivos de ahorro personalizados. Finova te ayuda a mantenerte enfocado y motivado.",
      "widget": Lottie.asset(
        'assets/lottie/SavingAndFinancialGrowth.json',
        height: 300,
        fit: BoxFit.contain,
      ),
      
    },
    {
      "title": "Gestión y Análisis",
      "subtitle":
          "Visualiza tus estadísticas financieras y descubre cómo mejorar tus hábitos de gasto con reportes y análisis en tiempo real.",
      "widget": Lottie.asset(
        'assets/lottie/GrowthAndAnalytics.json',
        height: 300,
        fit: BoxFit.contain,
      ),
    },
  ];

  void nextPage() {
    if (currentPage < onboardingData.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const RegisterScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) => setState(() => currentPage = index),
                itemCount: onboardingData.length,
                itemBuilder: (context, index) {
                  final item = onboardingData[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FadeInDown(
                          duration: const Duration(milliseconds: 800),
                          child: item["widget"],
                        ),
                        const SizedBox(height: 40),
                        FadeInUp(
                          duration: const Duration(milliseconds: 700),
                          child: Text(
                            item["title"]!,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: colorScheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        FadeInUp(
                          delay: const Duration(milliseconds: 300),
                          child: Text(
                            item["subtitle"]!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: colorScheme.onSurface.withAlpha(179),
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            /// 🔘 Indicadores + botón
            Padding(
              padding: const EdgeInsets.only(bottom: 24, left: 24, right: 24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(onboardingData.length, (index) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        height: 8,
                        width: currentPage == index ? 26 : 10,
                        decoration: BoxDecoration(
                          color: currentPage == index
                              ? colorScheme.primary
                              : colorScheme.primary.withAlpha(100),
                          borderRadius: BorderRadius.circular(20),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: nextPage,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 55),
                      backgroundColor: colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 6,
                      shadowColor: colorScheme.primary.withAlpha(50),
                    ),
                    child: Text(
                      currentPage == onboardingData.length - 1
                          ? 'Comenzar'
                          : 'Siguiente',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                   ElevatedButton(
                    onPressed: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    ),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 55),
                      backgroundColor: colorScheme.onSurface,
                      foregroundColor: colorScheme.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 6,
                      shadowColor: colorScheme.primary.withAlpha(50),
                    ),
                    child: Text(
                     'Iniciar Sesión',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
