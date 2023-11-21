﻿/************************************************************************
 * @description Исходный код программы состоит из одного этого файла.
 * @file ЗапускалкаTestMem5.ahk
 * @author CoolCmd
 * @license См. файл LICENSE.
 ***********************************************************************/

ВЕРСИЯ_ПРОГРАММЫ := '2023.11.21'
;@Ahk2Exe-Let U_ВерсияПрограммы = %A_PriorLine~^[^']+'|'$%

ИМЯ_ПРОГРАММЫ := 'Запускалка TestMem5'
;@Ahk2Exe-Let U_ИмяПрограммы = %A_PriorLine~^[^']+'|'$%

АВТОР_ПРОГРАММЫ := '© 2023 CoolCmd'
;@Ahk2Exe-Let U_АвторПрограммы = %A_PriorLine~^[^']+'|'$%

САЙТ_ПРОГРАММЫ := 'https://github.com/CoolCmd/3aIIyckaJIkaTestMem5'

;@Ahk2Exe-SetVersion %U_ВерсияПрограммы% (AutoHotkey %A_AhkVersion%)
;@Ahk2Exe-SetName %U_ИмяПрограммы%
;@Ahk2Exe-SetDescription %U_ИмяПрограммы%
;@Ahk2Exe-SetCopyright %U_АвторПрограммы%
;@Ahk2Exe-SetLanguage 0x419
;@Ahk2Exe-SetInternalName %A_ScriptName%
; requestedExecutionLevel = highestAvailable
;@Ahk2Exe-UpdateManifest 2, %A_ScriptName%, %U_ВерсияПрограммы%.0

#warn
#requires AutoHotkey v2.0 64-bit
#singleInstance IGNORE
listLines(false)
keyHistory(0)
processSetPriority('HIGH')

ИМЯ_EXE_ФАЙЛА_ТЕСТА := 'tm5.exe'
ПУТЬ_К_ТЕКУЩЕМУ_ФАЙЛУ_КОНФИГУРАЦИИ := 'bin\cfg.link'
ОТПЕЧАТОК_ОКНА_ТЕСТА := 'TestMem5 v AHK_CLASS #32770'
ИДК_ПРОШЛО_ВРЕМЕНИ := 0x191
ИДК_КОЛИЧЕСТВО_ОШИБОК := 0x192

ПУТЬ_К_ФАЙЛУ_НАСТРОЕК := regExReplace(A_ScriptName, '\.[^.]*$') '.ini'
ИД_ГЛАВНОГО_ЗНАЧКА := 159

идПроцессаТеста := 0
hwndОкноТеста := 0
hwndКоличествоОшибок := 0
окноНастроек := 0

; Имена контролов в окне настроек и имена ключей в файле настроек совпадают с именами свойств этого объекта.
настройки :=
{
	прерватьТестирование: true,
	проигратьЗвук: true,
	показатьУведомление: true,
	развернутьОкно: true,
	мигатьЗаголовком: true
}

поехали()

поехали()
{
	настроитьЗначокВТрее()
	восстановитьНастройкиИзФайла()
	if processExist(ИМЯ_EXE_ФАЙЛА_ТЕСТА)
	{
		msgBox('Тест уже запущен',, 48)
		exitApp()
	}
	задатьТекущуюКонфигурациюЕслиНужно()
	if not запуститьТест()
	{
		msgBox('Не удалось запустить ' ИМЯ_EXE_ФАЙЛА_ТЕСТА '. Это файл должен находиться в той же папке, что и ' a_ScriptName,, 16)
		exitApp()
	}
	setTimer(проверитьСостояниеТеста, 1000)
	persistent()
}

/**
 * Считывает настройки из файла и обновляет свойства переменной |настройки|.
 */
восстановитьНастройкиИзФайла()
{
	for имяНастройки in настройки.ownProps()
	{
		switch iniRead(ПУТЬ_К_ФАЙЛУ_НАСТРОЕК, 'настройки', имяНастройки, '')
		{
		case '0':
			настройки.%имяНастройки% := false
		case '1':
			настройки.%имяНастройки% := true
		}
	}
}

/**
 * Сменить файл конфигурации на указанный в командной строке.
 */
задатьТекущуюКонфигурациюЕслиНужно()
{
	if a_Args.length !== 0
	{
		атрибутыФайла := '*'
		try
		{
			; Пользователь может перетащить файл конфигурации на ярлык, в котором уже указана
			; конфигурация. Таким образом, в командной строке может быть две конфигурации.
			; Нам нужна последняя, перетаскиваемая.
			путьКФайлу := получитьАбсолютныйПуть(a_Args[a_Args.length])
			атрибутыФайла := fileGetAttrib(путьКФайлу)
		}
		if атрибутыФайла == '*' or inStr(атрибутыФайла, 'D')
		{
			msgBox('Не найден указанный в командной строке файл ' a_Args[a_Args.length],, 16)
		}
		else if strCompare(путьКФайлу, получитьТекущуюКонфигурацию(), 'LOCALE')
		{
			задатьТекущуюКонфигурацию(путьКФайлу)
		}
	}
}

/**
 * @returns {string}
 */
получитьТекущуюКонфигурацию()
{
	try return fileRead(ПУТЬ_К_ТЕКУЩЕМУ_ФАЙЛУ_КОНФИГУРАЦИИ, 'CP0')
	return ''
}

/**
 * @param {string} путьКФайлу
 */
задатьТекущуюКонфигурацию(путьКФайлу)
{
	try
	{
		файл := fileOpen(ПУТЬ_К_ТЕКУЩЕМУ_ФАЙЛУ_КОНФИГУРАЦИИ, 'w', 'CP0')
		файл.write(путьКФайлу)
		файл.close()
	}
	catch
	{
		msgBox('Не удалось записать в файл ' ПУТЬ_К_ТЕКУЩЕМУ_ФАЙЛУ_КОНФИГУРАЦИИ,, 16)
	}
}

/**
 * Преобразует путь из относительного в абсолютный с учетом a_WorkingDir.
 * @param {string} относительныйПуть Относительный путь к файлу или папке.
 * @returns {string} Абсолютный путь к файлу или папке.
 */
получитьАбсолютныйПуть(относительныйПуть)
{
	if размерБуфера := dllCall('GetFullPathNameW', 'STR', относительныйПуть, 'UINT', 0, 'PTR', 0, 'PTR', 0, 'UINT')
	{
		буфер := Buffer(размерБуфера * 2)
		if dllCall("GetFullPathNameW", 'STR', относительныйПуть, 'UINT', размерБуфера, 'PTR', буфер, 'PTR', 0, 'UINT')
		{
			return strGet(буфер)
		}
	}
	throw OSError()
}

/**
 * @returns {boolean} Удалось запустить тест?
 */
запуститьТест()
{
	try
	{
		global идПроцессаТеста
		run(ИМЯ_EXE_ФАЙЛА_ТЕСТА, a_InitialWorkingDir,, &идПроцессаТеста)
	}
	catch
	{
		return false
	}
	a_TitleMatchMode := 1
	global hwndОкноТеста := winWait(ОТПЕЧАТОК_ОКНА_ТЕСТА ' AHK_PID ' идПроцессаТеста,, 10)
	global hwndКоличествоОшибок := dllCall('GetDlgItem', 'PTR', hwndОкноТеста, 'INT', ИДК_КОЛИЧЕСТВО_ОШИБОК, 'PTR')
	return hwndКоличествоОшибок !== 0
}

/**
 * Обработчик таймера.
 */
проверитьСостояниеТеста()
{
	if not dllCall('IsWindow', 'PTR', hwndКоличествоОшибок, 'INT')
	{
		exitApp()
	}
	; TODO Отслеживать исключения в рабочем потоке: Thread Error Handler.
	static найденаОшибка := false
	if not найденаОшибка and dllCall('GetWindowTextLengthW', 'PTR', hwndКоличествоОшибок, 'INT')
	{
		найденаОшибка := true
		прерватьТестирование()
		уведомитьОбОшибке()
	}
}

прерватьТестирование()
{
	if настройки.прерватьТестирование
	{
		найтиПотокиТеста(идПроцессаТеста, &идГлавногоПотока, &идРабочегоПотока)
		if идРабочегоПотока
		{
			остановитьПоток(идРабочегоПотока)
		}
		убитьРабочиеПроцессыТеста()
		; Сменить идентификатор контрола с прошедшим временем на IDC_STATIC, чтобы тест не смог его изменить.
		; Или можно остановить таймер обновления окна, но это значительно сложнее.
		контрол := dllCall('GetDlgItem', 'PTR', hwndОкноТеста, 'INT', ИДК_ПРОШЛО_ВРЕМЕНИ, 'PTR')
		dllCall('SetWindowLongW', 'PTR', контрол, 'INT', -12, 'INT', -1, 'INT')
		; Изменить заголовок окна теста, чтобы пользователь понял, почему перестало идти время.
		; Это безопасно даже если процесс теста завис.
		dllCall('SetWindowTextW', 'PTR', hwndОкноТеста, 'PTR', strPtr('ТЕСТИРОВАНИЕ ПРЕРВАНО'), 'INT')
	}
}

/**
 * Ищет в указанном процессе теста идентификаторы главного и служебного потоков.
 * Если рабочий поток был убит, то вызывать функцию нельзя, потому что вместо рабочего
 * потока она может вернуть служебный поток винды.
 * @param {integer} идПроцессаТеста
 * @param {integer} идГлавногоПотока [out] 0 - поток не найден.
 * @param {integer} идРабочегоПотока [out] 0 - поток не найден.
 */
найтиПотокиТеста(идПроцессаТеста, &идГлавногоПотока, &идРабочегоПотока)
{
	;
	; У каждого процесса теста есть главный поток и рабочий поток. После создания процесса винда передает
	; управление главному потоку. В главном процессе главный поток показывает главное окно. И в главном,
	; и в рабочих процессах главный поток создает рабочий поток, который занимается тестированием памяти.
	; (Тестировать память в главном процессе - это странное решение.) Найти главный поток достаточно
	; просто. Главный поток всегда первый в списке, который возвращает CreateToolhelp32Snapshot(). Такое
	; поведение не документировано, поэтому ищем поток с самой ранней датой создания. Рабочий поток найти
	; сложнее. Винда создает свои служебные потоки, которые можно спутать с рабочим. Виндовые потоки, в
	; отличие от рабочего, тратят мало процессорного времени, поэтому ищем поток, который дольше всех
	; выполнялся вне ядра. Не самое красивое решение.
	;
	идГлавногоПотока := 0, времяСозданияГлавногоПотока := 0x7fffffffffffffff
	идРабочегоПотока := 0, времяВнеЯдраРабочегоПотока := 0
	; TH32CS_SNAPTHREAD
	снимок := dllCall('CreateToolhelp32Snapshot', 'UINT', 4, 'UINT', 0, 'PTR')
	данныеПотока := Buffer(28)
	numPut('UINT', данныеПотока.size, данныеПотока)
	результат := dllCall('Thread32First', 'PTR', снимок, 'PTR', данныеПотока, 'INT')
	while результат
	{
		; th32OwnerProcessID
		if numGet(данныеПотока, 12, 'UINT') == идПроцессаТеста
		{
			идПотока := numGet(данныеПотока, 8, 'UINT')
			;@Ahk2Exe-IgnoreBegin
			outputDebug(format('{}: идПотока={}`n', a_ThisFunc, идПотока))
			;@Ahk2Exe-IgnoreEnd
			; THREAD_QUERY_LIMITED_INFORMATION
			if поток := dllCall('OpenThread', 'UINT', 0x0800, 'INT', 0, 'UINT', идПотока, 'PTR')
			{
				if dllCall('GetThreadTimes', 'PTR', поток, 'INT64*', &времяСоздания := 0, 'INT64*', &времяЗавершения := 0
					, 'INT64*', &времяВЯдре := 0, 'INT64*', &времяВнеЯдра := 0, 'INT')
				{
					;@Ahk2Exe-IgnoreBegin
					outputDebug(format('{}: времяСоздания={} времяВЯдре={:.2f} времяВнеЯдра={:.2f}`n'
						, a_ThisFunc, времяСоздания, времяВЯдре / 10000000, времяВнеЯдра / 10000000))
					;@Ahk2Exe-IgnoreEnd
					if времяСоздания < времяСозданияГлавногоПотока
					{
						идГлавногоПотока := идПотока
						времяСозданияГлавногоПотока := времяСоздания
					}
					if времяВнеЯдра > времяВнеЯдраРабочегоПотока
					{
						идРабочегоПотока := идПотока
						времяВнеЯдраРабочегоПотока := времяВнеЯдра
					}
				}
				dllCall('CloseHandle', 'PTR', поток, 'INT')
			}
		}
		результат := dllCall('Thread32Next', 'PTR', снимок, 'PTR', данныеПотока, 'INT')
	}
	dllCall('CloseHandle', 'PTR', снимок, 'INT')
	; TODO времяВнеЯдраРабочегоПотока должно превышать 100 мс?
	if идРабочегоПотока == идГлавногоПотока
	{
		идРабочегоПотока := 0
	}
}

/**
 * @param {integer} идПотока
 * @returns {boolean} Поток остановлен?
 */
остановитьПоток(идПотока)
{
	; THREAD_SUSPEND_RESUME
	поток := dllCall('OpenThread', 'UINT', 2, 'INT', 0, 'UINT', идПотока, 'PTR')
	; Мелкософт пугает, что после TerminateThread() могут быть проблемы у других потоков этого
	; процесса. На всякий случай, не убиваем поток, а останавливаем его выполнение.
	результат := dllCall('SuspendThread', 'PTR', поток, 'UINT')
	dllCall('CloseHandle', 'PTR', поток, 'INT')
	;@Ahk2Exe-IgnoreBegin
	outputDebug(format('{}: идПотока={} поток={:p} результат={:#x}`n', a_ThisFunc, идПотока, поток, результат))
	;@Ahk2Exe-IgnoreEnd
	return результат !== 0xffffffff
}

/**
 * Тест плодит кучу рабочих процессов, которые занимаются тестированием памяти. Убить их всех.
 */
убитьРабочиеПроцессыТеста()
{
	идПроцессов := Buffer(10000 * 4)
	if dllCall('K32EnumProcesses', 'PTR', идПроцессов, 'UINT', идПроцессов.size, 'UINT*', &размер := 0, 'INT')
	{
		смещение := 0
		while смещение < размер
		{
			идПроцесса := numGet(идПроцессов, смещение, 'UINT')
			смещение += 4

			идРодительскогоПроцесса := 0
			try идРодительскогоПроцесса := processGetParent(идПроцесса)
			if идРодительскогоПроцесса !== идПроцессаТеста
			{
				continue
			}

			имяПроцесса := ''
			try имяПроцесса := processGetName(идПроцесса)
			if strCompare(имяПроцесса, ИМЯ_EXE_ФАЙЛА_ТЕСТА, 'LOCALE')
			{
				continue
			}

			результат := processClose(идПроцесса)
			;@Ahk2Exe-IgnoreBegin
			outputDebug(format('{}: идПроцесса={} результат={}`n', a_ThisFunc, идПроцесса, результат))
			;@Ahk2Exe-IgnoreEnd
		}
	}
}

уведомитьОбОшибке()
{
	if настройки.проигратьЗвук
	{
		; Стандартный звук винды для сообщения об ошибке.
		soundPlay('*16')
	}

	if настройки.показатьУведомление
	{
		; Всплывающее уведомление в десятой версии винды или пузырь в трее в старых версиях винды.
		; Стандартный значок винды для сообщения об ошибке | уведомление без звука.
		trayTip('MemTest5 нашел ошибку',, 3 | 16)
	}

	; Сделать кнопку на панели задач красной.
	try
	{
		; https://www.autohotkey.com/boards/viewtopic.php?t=67431
		taskbarList3 := comObject('{56FDF344-FD6D-11D0-958A-006097C9A090}', '{EA1AFB91-9E28-4B86-90E9-9E9F8A5EEFAF}')
		; ITaskbarList3::SetProgressValue()
		comCall(9, taskbarList3, 'PTR', hwndОкноТеста, 'UINT64', 1, 'UINT64', 1)
		; ITaskbarList3::SetProgressState(TBPF_ERROR)
		comCall(10, taskbarList3, 'PTR', hwndОкноТеста, 'INT', 4)
	}

	if winExist('A') == hwndОкноТеста
	{
		if настройки.мигатьЗаголовком
		{
			; Сделать окно неактивным, чтобы работало мигание.
			dllCall('SetForegroundWindow', 'PTR', dllCall('GetDesktopWindow', 'PTR'), 'INT')
		}
	}
	else
	{
		if настройки.развернутьОкно
		{
			; Развернуть свернутое окно. Оставить окно неактивным, чтобы работало мигание,
			; и чтобы не прерывать ввод текста пользователя.
			; SW_SHOWNOACTIVATE
			dllCall('ShowWindowAsync', 'PTR', hwndОкноТеста, 'INT', 4, 'INT')
			; Разместить окно поверх других окон. Полноэкранная игра будет свернута, полноэкранное видео - нет.
			; HWND_TOPMOST, SWP_ASYNCWINDOWPOS | SWP_NOACTIVATE | SWP_NOMOVE | SWP_NOSIZE
			dllCall('SetWindowPos', 'PTR', hwndОкноТеста, 'PTR', -1, 'INT', 0, 'INT', 0, 'INT', 0, 'INT', 0
				, 'UINT', 0x4000 | 0x0010 | 0x0002 | 0x0001, 'INT')
			; Разрешить другим окнам перекрывать окно.
			; HWND_NOTOPMOST, SWP_ASYNCWINDOWPOS | SWP_NOACTIVATE | SWP_NOMOVE | SWP_NOSIZE
			dllCall('SetWindowPos', 'PTR', hwndОкноТеста, 'PTR', -2, 'INT', 0, 'INT', 0, 'INT', 0, 'INT', 0
				, 'UINT', 0x4000 | 0x0010 | 0x0002 | 0x0001, 'INT')
			; TODO Вызвать SwitchToThread(hwndОкноТеста)?
		}
	}

	if настройки.мигатьЗаголовком
	{
		; Мигать заголовком окна и кнопкой на панели задач пока пользователь не переключится на это окно.
		структура := Buffer(32, 0)
		numPut('UINT', структура.size, структура)
		numPut('PTR', hwndОкноТеста, структура, 8)
		; FLASHW_CAPTION | FLASHW_TRAY | FLASHW_TIMERNOFG
		numPut('UINT', 1 | 2 | 12, структура, 16)
		dllCall('FlashWindowEx', 'PTR', структура, 'INT')
	}
}

настроитьЗначокВТрее()
{
	#noTrayIcon
	if a_IsCompiled
	{
		; Чтобы крупный значок окна не был мутным, загружаем его вручную. Если размер значка
		; в ресурсах равен 16x16, то для лучшего масштабирования он должен быть 256-цветным.
		dllCall('LoadIconMetric', 'PTR', dllCall('GetModuleHandleW', 'PTR', 0, 'PTR')
			, 'PTR', ИД_ГЛАВНОГО_ЗНАЧКА, 'INT', 0, 'PTR*', &значок := 0, 'HRESULT')
		traySetIcon('HICON:' значок)
	}
	;@Ahk2Exe-IgnoreBegin
	; Загруженный из ресурсов значок будет мутным. Для отладки и так сойдет.
	try traySetIcon(ИМЯ_EXE_ФАЙЛА_ТЕСТА)
	;@Ahk2Exe-IgnoreEnd
	a_TrayMenu.delete()
	a_TrayMenu.add('Настройки', открытьОкноНастроек)
	a_TrayMenu.add('Выйти', (*) => exitApp())
	a_TrayMenu.default := '1&'
	a_TrayMenu.clickCount := 1
	a_IconTip := ИМЯ_ПРОГРАММЫ
	a_IconHidden := false
}

получитьКрупныйЗначокОкна()
{
	static значок := 0
	if not значок
	{
		; В десятке размер значков на панели задач и Alt+Tab равен 24 пиксела вместо 32.
		; Десятка не отбрасывает дробную часть, а округляет до целого.
		размерЗначка := strSplit(a_OSVersion, '.')[1] >= 10 ? round(sysGet(11) * 3 / 4) : sysGet(11)
		if a_IsCompiled
		{
			; Чтобы крупный значок окна не был мутным, загружаем его вручную. Если размер значка
			; в ресурсах равен 16x16, то для лучшего масштабирования он должен быть 256-цветным.
			dllCall('LoadIconWithScaleDown'
				, 'PTR', dllCall('GetModuleHandleW', 'PTR', 0, 'PTR'), 'PTR', ИД_ГЛАВНОГО_ЗНАЧКА
				, 'INT', размерЗначка, 'INT', размерЗначка, 'PTR*', &значок := 0, 'HRESULT')
		}
		;@Ahk2Exe-IgnoreBegin
		; Загруженный из ресурсов значок будет мутным. Для отладки и так сойдет.
		значок := loadPicture(ИМЯ_EXE_ФАЙЛА_ТЕСТА, 'W' размерЗначка, &тип)
		;@Ahk2Exe-IgnoreEnd
	}
	return значок
}

открытьОкноНастроек(заголовокОкна, *)
{
	global окноНастроек
	if окноНастроек
	{
		окноНастроек.show()
		return
	}

	ИМЯ_ШРИФТА := 'Segoe UI'
	РАЗМЕР_ШРИФТА := 9 ; Пункты.

	МАКС_ШИРИНА_КОНТРОЛА := РАЗМЕР_ШРИФТА * 38
	ОТСТУП_ГРУППЫ_X := РАЗМЕР_ШРИФТА * 1.4 ; 1.4 / 1.1
	ОТСТУП_ГРУППЫ_Y := РАЗМЕР_ШРИФТА * 2.5 ; 2.5 / 2.3

	значок := получитьКрупныйЗначокОкна()

	окноНастроек := Gui(, заголовокОкна)
	окноНастроек.marginX := окноНастроек.marginY := РАЗМЕР_ШРИФТА
	окноНастроек.setFont('S' РАЗМЕР_ШРИФТА, ИМЯ_ШРИФТА)
	окноНастроек.addGroupBox('SECTION R1.5 W' МАКС_ШИРИНА_КОНТРОЛА, 'О программе')
	окноНастроек.addPicture('XP+' ОТСТУП_ГРУППЫ_X ' YP+' ОТСТУП_ГРУППЫ_Y, 'HICON:*' значок)
	окноНастроек.addLink('YP', ИМЯ_ПРОГРАММЫ '   ' ВЕРСИЯ_ПРОГРАММЫ
		. '`n' АВТОР_ПРОГРАММЫ '   <a href="' САЙТ_ПРОГРАММЫ '">Сайт программы</a>')
	окноНастроек.addGroupBox('XS R6 W' МАКС_ШИРИНА_КОНТРОЛА, 'После первой ошибки')
	; Имена контролов совпадают с именами свойств переменной |настройки|.
	окноНастроек.addCheckBox('VпрерватьТестирование'
		. ' XP+' ОТСТУП_ГРУППЫ_X ' YP+' ОТСТУП_ГРУППЫ_Y, 'Прервать тестирование').focus()
	окноНастроек.addCheckBox('VпроигратьЗвук', 'Проиграть звук')
	окноНастроек.addCheckBox('VпоказатьУведомление', 'Показать всплывающее уведомление')
	окноНастроек.addCheckBox('VразвернутьОкно', 'Переместить окно TestMem5 на передний план')
	окноНастроек.addCheckBox('VмигатьЗаголовком', 'Мигать заголовком окна и кнопкой на панели задач')
	окноНастроек.addCheckBox('CHECKED DISABLED', 'Сменить цвет кнопки на панели задач')
	окноНастроек.onEvent('ESCAPE', обработатьЗакрытиеОкнаНастроек)
	окноНастроек.onEvent('CLOSE', обработатьЗакрытиеОкнаНастроек)

	for имяНастройки in настройки.ownProps()
	{
		окноНастроек[имяНастройки].value := настройки.%имяНастройки%
		окноНастроек[имяНастройки].onEvent('CLICK', обработатьИзменениеНастройки)
	}

	; WM_SETICON, ICON_BIG
	sendMessage(0x80, 1, значок, окноНастроек)
	; TODO Открывать окно рядом с треем:
	; controlGetHwnd('TrayNotifyWnd1', 'AHK_CLASS Shell_TrayWnd')
	окноНастроек.show()
}

обработатьЗакрытиеОкнаНастроек(*)
{
	global окноНастроек
	окноНастроек.destroy()
	окноНастроек := 0
	return true
}

/**
 * @param {Gui.CheckBox} флажок
 * Обновляет свойство переменной |настройки| и записывает измененную настройку в файл.
 */
обработатьИзменениеНастройки(флажок, *)
{
	if настройки.%флажок.name% !== флажок.value
	{
		настройки.%флажок.name% := флажок.value
		try iniWrite(флажок.value, ПУТЬ_К_ФАЙЛУ_НАСТРОЕК, 'настройки', флажок.name)
	}
}
