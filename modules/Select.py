import tkinter
from tkinter import filedialog


def Item(self):
  for i, item in enumerate(self):
    print(f'{i + 1}. {item}')
  print(f'{len(self) + 1}. Use file chooser')
  while True:
    selection = int(input('\nSelect an option: '))
    if selection > 0 and selection <= len(self):
      return self[selection - 1]
    elif selection == len(self) + 1:
      return Directory()


def Directory(self = ''):
  root = tkinter.Tk()
  root.withdraw()
  self = filedialog.askdirectory(initialdir = self)
  root.destroy()
  return self