#ifndef GUI_APPLICATION_H
#define GUI_APPLICATION_H

#include <QApplication>

class Application : QApplication {
public:
  Application(int &argc, char **argv);
};

#endif
