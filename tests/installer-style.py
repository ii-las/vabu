#!/usr/bin/env python3
"""Render the production Qt stylesheet and exercise actual native controls in CI.

No Calamares jobs, accounts, device probes or external commands. Screenshots
include every checkbox state, radio choices, menus, tabs and form controls.
"""
import json
import os
from pathlib import Path
import sys

if sys.platform != 'linux' or os.environ.get('VABU_TEST_ISOLATED') != '1':
    raise SystemExit('Only runs in isolated Linux CI.')

from PyQt6.QtCore import Qt, QPoint, qInstallMessageHandler
from PyQt6.QtSvg import QSvgRenderer
from PyQt6.QtTest import QTest
from PyQt6.QtWidgets import (QApplication, QWidget, QVBoxLayout, QHBoxLayout,
    QLabel, QLineEdit, QCheckBox, QRadioButton, QComboBox, QSpinBox,
    QPushButton, QTabWidget, QGroupBox, QStyle, QStyleOptionButton)

out = Path(sys.argv[1]); out.mkdir(parents=True, exist_ok=True)
branding = Path(__file__).resolve().parents[1] / 'iso/root/etc/calamares/branding/vabu'
errors = []
def message(kind, context, text):
    if 'parse' in text.lower() or 'unknown property' in text.lower() or 'cannot' in text.lower():
        errors.append(text)
qInstallMessageHandler(message)
app = QApplication([])
app.setStyle('Fusion')
app.setStyleSheet((branding / 'stylesheet.qss').read_text().replace(
    '/etc/calamares/branding/vabu/', str(branding) + '/'))
for asset in (branding / 'assets').glob('*.svg'):
    assert QSvgRenderer(str(asset)).isValid(), 'Invalid vector asset: ' + str(asset)
window = QWidget(); window.setWindowTitle('Vabu — kontroller')
layout = QVBoxLayout(window); layout.setContentsMargins(32, 28, 32, 28); layout.setSpacing(18)
heading = QLabel('Kurulum kontrolleri'); heading.setObjectName('pageTitle'); layout.addWidget(heading)
layout.addWidget(QLabel('Giriş, seçim, odak ve pasif durumlar aynı görsel dili kullanır.'))
field = QLineEdit(); field.setPlaceholderText('Bilgisayar adı'); layout.addWidget(field)
combo = QComboBox(); combo.addItems(['Türkçe', 'English', 'Deutsch']); layout.addWidget(combo)
spin = QSpinBox(); spin.setRange(1, 64); spin.setValue(8); layout.addWidget(spin)
group = QGroupBox('Seçenekler'); checks = QHBoxLayout(group)
unchecked = QCheckBox('Kapalı'); checked = QCheckBox('Seçili'); checked.setChecked(True)
mixed = QCheckBox('Kısmen seçili'); mixed.setTristate(True); mixed.setCheckState(Qt.CheckState.PartiallyChecked)
disabled = QCheckBox('Pasif seçim'); disabled.setChecked(True); disabled.setEnabled(False)
for box in (unchecked, checked, mixed, disabled): checks.addWidget(box)
layout.addWidget(group)
r1 = QRadioButton('Mevcut alanı kullan'); r2 = QRadioButton('Başka bir alan seç'); r1.setChecked(True)
layout.addWidget(r1); layout.addWidget(r2)
tabs = QTabWidget(); tabs.addTab(QWidget(), 'Özet'); tabs.addTab(QWidget(), 'Ayrıntılar'); layout.addWidget(tabs)
buttons = QHBoxLayout(); back = QPushButton('Geri'); next_ = QPushButton('Devam'); next_.setDefault(True)
buttons.addStretch(); buttons.addWidget(back); buttons.addWidget(next_); layout.addLayout(buttons)
window.resize(960, 720); window.show(); QTest.qWait(150)
# Native editing and keyboard selection must still work after the stylesheet.
field.setFocus(); QTest.keyClicks(field, 'vabu-laptop'); assert field.text() == 'vabu-laptop'
QTest.mouseClick(unchecked, Qt.MouseButton.LeftButton, pos=QPoint(12, unchecked.height() // 2)); assert unchecked.isChecked()
QTest.keyClick(unchecked, Qt.Key.Key_Space); assert not unchecked.isChecked()
combo.setFocus(); QTest.keyClick(combo, Qt.Key.Key_Down); assert combo.currentIndex() == 1
spin.setFocus(); QTest.keyClick(spin, Qt.Key.Key_Up); assert spin.value() == 9
QTest.mouseClick(r2, Qt.MouseButton.LeftButton, pos=QPoint(22, r2.height() // 2)); assert r2.isChecked() and not r1.isChecked()
# Check rendered indicator pixels: a filled rectangle without a tick must fail.
for box in (checked, mixed, disabled):
    option = QStyleOptionButton(); box.initStyleOption(option)
    rect = box.style().subElementRect(QStyle.SubElement.SE_CheckBoxIndicator, option, box)
    image = box.grab(rect).toImage()
    whites = sum(image.pixelColor(x, y).red() > 240 and image.pixelColor(x, y).green() > 240
                 and image.pixelColor(x, y).blue() > 240
                 for x in range(image.width() // 4, image.width() * 3 // 4)
                 for y in range(image.height() // 4, image.height() * 3 // 4))
    assert whites >= 8, 'Missing tick or partial-selection mark: ' + box.text()
field.setFocus(); QTest.qWait(100)
assert window.grab().save(str(out / '55-kurulum-kontroller.png'))
combo.showPopup(); QTest.qWait(100)
assert combo.view().window().grab().save(str(out / '56-kurulum-dil-listesi.png'))
combo.hidePopup()
assert not errors, errors
(out / 'calamares-style.json').write_text(json.dumps({
    'nativeControls': True, 'renderedTicks': True, 'vectorsValid': True,
    'keyboardEditing': True, 'checkboxRadioComboSpin': True, 'styleErrors': errors
}, indent=2) + '\n')
print('Production installer stylesheet: rendering, vectors, state marks and native input passed.')
