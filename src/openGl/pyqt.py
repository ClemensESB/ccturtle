import sys
from PyQt5.QtWidgets import QApplication, QWidget, QPushButton, QHBoxLayout



class Window:
    def __init__(self,width,height):
            self.app = QApplication(sys.argv)
            self.window = QWidget()
            self.window.resize(width, height)
            self.window.move(100, 100)
            self.window.setWindowTitle("turtle")
            #self.window.setWindowIcon(QtGui.QIcon('icon.png'))
            self.window.show()

    def addButton(self):
        layout = QHBoxLayout()
        btn = QPushButton("test")
        layout.addWidget(btn)
        self.window.setLayout(layout)


    def exit(self):
        self.app.exec_()


if __name__ == '__main__':
    win = Window(1240, 720)
    win.addButton()
    
    
    sys.exit(win.exit())

    

