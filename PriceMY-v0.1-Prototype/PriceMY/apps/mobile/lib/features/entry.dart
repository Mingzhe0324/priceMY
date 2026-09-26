import 'dart:async';
import 'package:flutter/material.dart';
import '../core/app_state.dart';
import '../core/theme.dart';
import '../widgets/common.dart';
import 'shell.dart';

class Entry extends StatefulWidget {
  final AppState state;
  const Entry({super.key, required this.state});
  @override
  State<Entry> createState() => _EntryState();
}

class _EntryState extends State<Entry> {
  int stage = 0, slide = 0;
  bool register = false;
  Timer? timer;
  final form = GlobalKey<FormState>();
  final email = TextEditingController(),
      password = TextEditingController(),
      name = TextEditingController();
  @override
  void initState() {
    super.initState();
    timer = Timer(const Duration(milliseconds: 1100), () {
      if (mounted) setState(() => stage = widget.state.onboarded ? 2 : 1);
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    email.dispose();
    password.dispose();
    name.dispose();
    super.dispose();
  }

  void enter() {
    widget.state.name = name.text.trim().isEmpty ? 'Guest' : name.text.trim();
    setState(() => stage = 3);
  }

  @override
  Widget build(BuildContext context) {
    final titles = [
      'A better price.\nA smarter everyday.',
      'Same product.\nA clearer choice.',
      'Your basket.\nBetter together.',
    ];
    final descriptions = [
      'Compare everyday essentials across Malaysia, in one calm space.',
      'Compare the exact brand, variant and pack size. Know where every price comes from.',
      'Find your best single-store basket, or see what splitting your shop could save.',
    ];
    return AnimatedSwitcher(
      duration: MediaQuery.of(context).disableAnimations
          ? Duration.zero
          : const Duration(milliseconds: 450),
      child: stage == 3
          ? Shell(
              key: const ValueKey('shell'),
              state: widget.state,
              onLogout: () => setState(() => stage = 2),
            )
          : Scaffold(
              key: ValueKey(stage),
              body: SafeArea(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: stage == 0
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: ink,
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: const Icon(
                                    Icons.shopping_bag_outlined,
                                    size: 50,
                                    color: lime,
                                  ),
                                ),
                                gap(22),
                                const Text(
                                  'PriceMY',
                                  style: TextStyle(
                                    fontSize: 38,
                                    fontWeight: FontWeight.w800,
                                    color: ink,
                                  ),
                                ),
                                const Text(
                                  'Worth every ringgit.',
                                  style: TextStyle(color: muted),
                                ),
                              ],
                            )
                          : stage == 1
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'PriceMY',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        widget.state.finishOnboarding();
                                        setState(() => stage = 2);
                                      },
                                      child: const Text('Skip'),
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                Center(
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Container(
                                        width: 240,
                                        height: 240,
                                        decoration: const BoxDecoration(
                                          color: lime,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      Icon(
                                        [
                                          Icons.shopping_bag_outlined,
                                          Icons.compare_arrows_rounded,
                                          Icons.account_balance_wallet_outlined,
                                        ][slide],
                                        size: 110,
                                        color: ink,
                                      ),
                                      Positioned(
                                        bottom: 12,
                                        right: 0,
                                        child: Panel(
                                          child: Text(
                                            [
                                              'Less searching. More saving.',
                                              'Exact match ✓',
                                              'One list. More possibilities.',
                                            ][slide],
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  titles[slide],
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineLarge,
                                ),
                                gap(),
                                Text(
                                  descriptions[slide],
                                  style: const TextStyle(
                                    color: muted,
                                    fontSize: 16,
                                    height: 1.6,
                                  ),
                                ),
                                gap(30),
                                Row(
                                  children: List.generate(
                                    3,
                                    (i) => AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      width: i == slide ? 28 : 7,
                                      height: 7,
                                      margin: const EdgeInsets.only(right: 7),
                                      decoration: BoxDecoration(
                                        color: i == slide
                                            ? ink
                                            : const Color(0xFFDBE1D6),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                  ),
                                ),
                                gap(24),
                                FilledButton(
                                  onPressed: () {
                                    if (slide < 2) {
                                      setState(() => slide++);
                                    } else {
                                      widget.state.finishOnboarding();
                                      setState(() => stage = 2);
                                    }
                                  },
                                  child: Text(
                                    slide == 2
                                        ? 'Let’s get started'
                                        : 'Continue',
                                  ),
                                ),
                                gap(),
                              ],
                            )
                          : SingleChildScrollView(
                              child: Form(
                                key: form,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'PriceMY',
                                      style: TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    gap(50),
                                    Text(
                                      register
                                          ? 'Your smarter shop\nstarts here.'
                                          : 'Welcome to\nbetter choices.',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.headlineLarge,
                                    ),
                                    gap(),
                                    const Text(
                                      'Demo mode · no account is created.\nUse sample details, or explore as a guest.',
                                      style: TextStyle(color: muted),
                                    ),
                                    gap(30),
                                    if (register) ...[
                                      TextFormField(
                                        controller: name,
                                        decoration: const InputDecoration(
                                          labelText: 'Your name',
                                        ),
                                        validator: (v) =>
                                            (v ?? '').trim().isEmpty
                                            ? 'Please enter a name'
                                            : null,
                                      ),
                                      gap(),
                                    ],
                                    TextFormField(
                                      controller: email,
                                      keyboardType: TextInputType.emailAddress,
                                      decoration: const InputDecoration(
                                        labelText: 'Email address',
                                      ),
                                      validator: (v) =>
                                          RegExp(
                                            r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                                          ).hasMatch(v ?? '')
                                          ? null
                                          : 'Enter a valid demo email',
                                    ),
                                    gap(),
                                    TextFormField(
                                      controller: password,
                                      obscureText: true,
                                      decoration: const InputDecoration(
                                        labelText: 'Demo password',
                                      ),
                                      validator: (v) => (v ?? '').length >= 8
                                          ? null
                                          : 'Use at least 8 characters',
                                    ),
                                    gap(24),
                                    FilledButton(
                                      onPressed: () {
                                        if (form.currentState!.validate()) {
                                          password.clear();
                                          enter();
                                        }
                                      },
                                      child: Text(
                                        register
                                            ? 'Create demo profile'
                                            : 'Continue in demo',
                                      ),
                                    ),
                                    gap(),
                                    Center(
                                      child: TextButton(
                                        onPressed: () {
                                          password.clear();
                                          enter();
                                        },
                                        child: const Text('Explore as guest →'),
                                      ),
                                    ),
                                    Center(
                                      child: TextButton(
                                        onPressed: () => setState(
                                          () => register = !register,
                                        ),
                                        child: Text(
                                          register
                                              ? 'Already have an account? Sign in'
                                              : 'New to PriceMY? Register',
                                        ),
                                      ),
                                    ),
                                    gap(24),
                                    const Text(
                                      'Nothing is sent to a server. Lists and alerts stay on this device; demo login details are not saved.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: muted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
