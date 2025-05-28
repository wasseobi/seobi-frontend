import 'package:flutter/material.dart';

class AppGradients {
  static const LinearGradient lightBackground = LinearGradient(
    begin: Alignment(0.27, 0.00),
    end: Alignment(0.50, 1.00),
    colors: [Color(0xFFF5EFED), Color(0xFFE9E4E1)],
  );

  static const LinearGradient darkBackground = LinearGradient(
    begin: Alignment(0.50, 1.00),
    end: Alignment(0.64, -0.00),
    colors: [Color(0xFF272727), Color(0xFF363636)],
  );
}

class AppColors {
  // Basic Colors
  static const Color white100 = Color(0xFFFFFFFF);
  static const Color white80 = Color(0xFFF6F6F6);
  static const Color whiteBlur = Color.fromRGBO(255, 255, 255, 0.6);
  static const Color black100 = Color(0xFF272727);
  static const Color gray100 = Color(0xFF505050);
  static const Color gray80 = Color(0xFF7D7D7D);
  static const Color gray60 = Color(0xFFADB3BC);
  static const Color gray40 = Color(0xFFE9E4E2);
  static const Color main100 = Color(0xFFFF7B34);
  static const Color main80 = Color(0xFFFFB289);
  static const Color green100 = Color(0xFF03C009);

  // general/text
  static const Color textDarkPrimary = white100;
  static const Color textDarkSecondary = white80; //icon포함
  static const Color textLightPrimary = gray100;
  static const Color textLightSecondary = gray80; // icon포함

  // general/container
  static const Color containerDark = gray100;
  static const Color containerLight = white100;

  // general/button
  static const Color buttonDarkBg = black100;
  static const Color buttonLightBg = white80;
  static const Color buttonIconPrimary = main100;
  static const Color buttonIconSecondary = gray80;

  // Custom tab bar (navigation, nav로 통칭)
  static const Color navBox = main100;
  static const Color navSelectedLight = white100;
  static const Color navSelectedDark = black100;
  static const Color navSelectedWhilePressed = main80;
  static const Color navIcon = white100;
  static const Color navOpenSidebar = gray80;

  // Chat screen (chat으로 통칭) (Background는 Gradient 활용)
  static const Color chatMsgBox = main80;
  static const Color chatLogBox = white80;
  static const Color chatLine = gray80;
}
