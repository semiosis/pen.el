#include "gui/Application.hpp"
#include <QtGlobal>

int main(int argc, char **argv) {
  Application app(argc, argv);

#if QT_VERSION >= QT_VERSION_CHECK(5, 6, 0)
  QApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
#endif

  return app.exec();
}
