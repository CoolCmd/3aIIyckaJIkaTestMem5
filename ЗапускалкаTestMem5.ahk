﻿/************************************************************************
 * @description Исходный код программы состоит из одного этого файла.
 * @file ЗапускалкаTestMem5.ahk
 * @author CoolCmd
 * @license См. файл LICENSE.
 ***********************************************************************/

ВЕРСИЯ_ПРОГРАММЫ := '2023.12.06'
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
ПУТЬ_К_ТЕКУЩЕМУ_ФАЙЛУ_КОНФИГУРАЦИИ := 'bin\Cfg.link'
ПУТЬ_К_ЖУРНАЛУ_ТЕСТИРОВАНИЯ := a_InitialWorkingDir '\Log.txt'
ПУТЬ_К_ЖУРНАЛУ_ПАДЕНИЯ := a_InitialWorkingDir '\Crash.log'
ОТПЕЧАТОК_ОКНА_ТЕСТА := 'TestMem5 v0.12 AHK_CLASS #32770'
ОТПЕЧАТОК_ОКНА_УПАВШЕГО_ПРОЦЕССА := 'TM5 crash! AHK_CLASS #32770 AHK_EXE ' ИМЯ_EXE_ФАЙЛА_ТЕСТА
ИДК_ПРОШЛО_ВРЕМЕНИ := 0x191
ИДК_КОЛИЧЕСТВО_ОШИБОК := 0x192
ИДК_ИСПОЛЬЗОВАНО_ПАМЯТИ := 0x0cb

ИД_ГЛАВНОГО_ЗНАЧКА := 159
МИН_РАЗМЕР_ЖУРНАЛА := 0 ; Килобайты.
МАКС_РАЗМЕР_ЖУРНАЛА := 999 ; Килобайты.
ДОБАВИТЬ_К_РАЗМЕРУ_ЖУРНАЛА := 130 ; Проценты >= 100.

/** @type {integer?} */
идГлавногоПроцесса := unset
/** @type {integer?} */
hwndГлавноеОкно := unset
/** @type {integer?} */
hwndКоличествоОшибок := unset
/** @type {integer?} */
hwndИспользованоПамяти := unset
/**
 * Время начала тестирования. unset - тестирование не началось или закончилось.
 * @type {integer?}
 */
началоТестирования := unset
/**
 * unset - окно закрыто.
 * @type {Gui?}
 */
окноНастроек := unset

; Имена контролов в окне настроек и имена ключей в файле настроек совпадают с именами свойств этого объекта.
; TODO Переместить настройки, константы и функции в Map?
настройки :=
{
	/** @type {boolean} */
	прерватьТестирование: true,
	/** @type {boolean} */
	проигратьЗвук: true,
	/** @type {boolean} */
	показатьУведомление: true,
	/** @type {boolean} */
	развернутьОкно: true,
	/** @type {boolean} */
	мигатьЗаголовком: true,
	/** @type {1|2|3} */
	ограничитьРазмерЖурнала: 1,
	/**
	 * Размер журнала в килобайтах.
	 * @type {integer} МИН_РАЗМЕР_ЖУРНАЛА..МАКС_РАЗМЕР_ЖУРНАЛА
	 */
	размерЖурнала: 5
}

поехали()

поехали()
{
	настроитьЗначокВТрее()
	восстановитьНастройкиИзФайла()
	if processExist(ИМЯ_EXE_ФАЙЛА_ТЕСТА)
	{
		msgBox('TestMem5 уже запущен',, 48)
		exitApp()
	}
	ограничитьРазмерЖурнала()
	задатьТекущуюКонфигурациюЕслиНужно()
	if not запуститьТест()
	{
		exitApp()
	}
	setTimer(проверитьСостояниеТеста, 1000)
	onExit(обработатьЗавершениеПрограммы)
	persistent()
}

/**
 * @returns {string} Путь к файлу, в котором хранятся настройки программы.
 */
получитьПутьКФайлуНастроек()
{
	static путь := ''
	if not путь
	{
		точка := inStr(a_ScriptName, '.', true, -1)
		путь := subStr(a_ScriptName, 1, точка ? точка - 1 : 999999) '.ini'
	}
	return путь
}

/**
 * @param {string} строка
 * @returns {integer}
 */
перевестиСтрокуВРазмерЖурнала(строка)
{
	число := настройки.размерЖурнала
	try число := Integer(строка)
	return min(max(число, МИН_РАЗМЕР_ЖУРНАЛА), МАКС_РАЗМЕР_ЖУРНАЛА)
}

/**
 * Считывает настройки из файла в переменную |настройки|.
 */
восстановитьНастройкиИзФайла()
{
	for имяНастройки in настройки.ownProps()
	{
		строка := iniRead(получитьПутьКФайлуНастроек(), 'настройки', имяНастройки, '')
		switch имяНастройки
		{
		case 'ограничитьРазмерЖурнала':
			switch строка
			{
				case '1': настройки.ограничитьРазмерЖурнала := 1
				case '2': настройки.ограничитьРазмерЖурнала := 2
				case '3': настройки.ограничитьРазмерЖурнала := 3
			}

		case 'размерЖурнала':
			настройки.размерЖурнала := перевестиСтрокуВРазмерЖурнала(строка)

		default:
			switch строка
			{
				case '0': настройки.%имяНастройки% := false
				case '1': настройки.%имяНастройки% := true
			}
		}
	}
}

ограничитьРазмерЖурнала()
{
	switch настройки.ограничитьРазмерЖурнала
	{
	case 1:
		;
		; Удалить файл.
		;
		атрибуты := fileExist(ПУТЬ_К_ЖУРНАЛУ_ПАДЕНИЯ)
		if атрибуты and not inStr(атрибуты, 'D')
		{
			try
			{
				if inStr(атрибуты, 'R')
				{
					fileSetAttrib('-R', ПУТЬ_К_ЖУРНАЛУ_ПАДЕНИЯ)
				}
				fileDelete(ПУТЬ_К_ЖУРНАЛУ_ПАДЕНИЯ)
			}
		}

		;
		; Ограничить размер файла.
		;
		атрибуты := fileExist(ПУТЬ_К_ЖУРНАЛУ_ТЕСТИРОВАНИЯ)
		if атрибуты and not inStr(атрибуты, 'D')
		{
			try
			{
				if inStr(атрибуты, 'R')
				{
					fileSetAttrib('-R', ПУТЬ_К_ЖУРНАЛУ_ТЕСТИРОВАНИЯ)
				}
				новыйРазмер := настройки.размерЖурнала * 1024
				if fileGetSize(ПУТЬ_К_ЖУРНАЛУ_ТЕСТИРОВАНИЯ) > новыйРазмер * ДОБАВИТЬ_К_РАЗМЕРУ_ЖУРНАЛА // 100
				{
					if новыйРазмер == 0
					{
						файл := fileOpen(ПУТЬ_К_ЖУРНАЛУ_ТЕСТИРОВАНИЯ, 'w', 'CP0')
					}
					else
					{
						файл := fileOpen(ПУТЬ_К_ЖУРНАЛУ_ТЕСТИРОВАНИЯ, 'rw-', 'CP0')
						if файл.seek(-новыйРазмер)
						{
							текст := файл.read(новыйРазмер)
							; Пропустить частично обрезанную строку.
							if конецСтроки := inStr(текст, '`r`n', true)
							{
								текст := subStr(текст, конецСтроки + 2)
							}
							if файл.seek(0)
							{
								файл.length := файл.write(текст)
							}
						}
					}
					файл.close()
				}
			}
		}

	case 2:
		; Удалить содержимое файла и поставить защиту от записи.
		for путь in [ПУТЬ_К_ЖУРНАЛУ_ТЕСТИРОВАНИЯ, ПУТЬ_К_ЖУРНАЛУ_ПАДЕНИЯ]
		{
			атрибуты := fileExist(путь)
			if not inStr(атрибуты, 'R') and not inStr(атрибуты, 'D')
			{
				try
				{
					; Удалить содержимое файла.
					fileOpen(путь, 'w', 'CP0').close()
					fileSetAttrib('+R', путь)
				}
			}
		}

	case 3:
		; Снять защиту от записи.
		for путь in [ПУТЬ_К_ЖУРНАЛУ_ТЕСТИРОВАНИЯ, ПУТЬ_К_ЖУРНАЛУ_ПАДЕНИЯ]
		{
			атрибуты := fileExist(путь)
			if inStr(атрибуты, 'R') and not inStr(атрибуты, 'D')
			{
				try fileSetAttrib('-R', путь)
			}
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
 * Вызывается один раз сразу после начала тестирования.
 */
обработатьНачалоТестирования()
{
	global началоТестирования
	;@Ahk2Exe-IgnoreBegin
	if isSet(началоТестирования)
	{
		throw 0
	}
	;@Ahk2Exe-IgnoreEnd

	началоТестирования := a_TickCount
	; Запретить винде уводить компьютер в сон (ES_CONTINUOUS | ES_SYSTEM_REQUIRED).
	dllCall('SetThreadExecutionState', 'INT', 0x80000001, 'INT')
}

/**
 * Вызывается один раз сразу после окончания тестирования.
 */
обработатьКонецТестирования()
{
	global началоТестирования
	;@Ahk2Exe-IgnoreBegin
	if not isSet(началоТестирования)
	{
		throw 0
	}
	;@Ahk2Exe-IgnoreEnd

	началоТестирования := unset
	; Разрешить винде уводить компьютер в сон (ES_CONTINUOUS).
	dllCall('SetThreadExecutionState', 'INT', 0x80000000, 'INT')
}

/**
 * @returns {boolean} Удалось запустить тест?
 */
запуститьТест()
{
	try
	{
		global идГлавногоПроцесса
		run(ИМЯ_EXE_ФАЙЛА_ТЕСТА, a_InitialWorkingDir,, &идГлавногоПроцесса)
	}
	catch
	{
		msgBox('Не удалось запустить ' ИМЯ_EXE_ФАЙЛА_ТЕСТА '. Это файл должен находиться в той же папке, что и ' a_ScriptName,, 16)
		return false
	}

	a_TitleMatchMode := 1, ждатьДо := a_TickCount + 10000
	loop
	{
		global hwndГлавноеОкно := winExist(ОТПЕЧАТОК_ОКНА_ТЕСТА ' AHK_PID ' идГлавногоПроцесса)
		global hwndКоличествоОшибок := dllCall('GetDlgItem', 'PTR', hwndГлавноеОкно, 'INT', ИДК_КОЛИЧЕСТВО_ОШИБОК, 'PTR')
		global hwndИспользованоПамяти := dllCall('GetDlgItem', 'PTR', hwndГлавноеОкно, 'INT', ИДК_ИСПОЛЬЗОВАНО_ПАМЯТИ, 'PTR')
		if hwndКоличествоОшибок and dllCall('GetWindowTextLengthW', 'PTR', hwndИспользованоПамяти, 'INT')
		{
			обработатьНачалоТестирования()
			return true
		}
		if a_TickCount >= ждатьДо or not processExist(идГлавногоПроцесса)
		{
			return false
		}
		sleep(100)
	}
}

/**
 * Обработчик таймера.
 */
проверитьСостояниеТеста()
{
	if not winExist(hwndКоличествоОшибок)
	{
		exitApp()
	}

	; Замечание. TestMem5 сообщает о завершении тестирования при бездействии одного (?) процесса.
	; Остальные процессы могу работать ещё несколько минут.
	if not isSet(началоТестирования)
	{
		return
	}

	; Слежение за падением потока в одном или нескольких процессах теста. Почти всегда падает рабочий поток.
	; При поимке исключения, поток прерывает работу, показывает MessageBox и убивает свой процесс.
	; Программа не сможет обнаружить падение, если пользователь закроет MessageBox слишком быстро.
	a_TitleMatchMode := 3
	if окноУпавшегоПроцесса := winExist(ОТПЕЧАТОК_ОКНА_УПАВШЕГО_ПРОЦЕССА)
	{
		; Оставить один упавший процесс, чтобы пользователь увидел его MessageBox. Упавший рабочий
		; поток уже прервал тестирование. Не останавливать упавший рабочий поток в главном процессе,
		; потому что открытые этим потоком окна станут прибиты к экрану гвоздями.
		окноУпавшегоПроцесса := winExist(ОТПЕЧАТОК_ОКНА_УПАВШЕГО_ПРОЦЕССА ' AHK_PID ' идГлавногоПроцесса) or окноУпавшегоПроцесса
		идУпавшегоПроцесса := 0
		try идУпавшегоПроцесса := winGetPID(окноУпавшегоПроцесса)

		текстУведомления := 'TestMem5 упал через ' получитьПрошедшееВремя() '. Тестирование прервано.'
		; Процесс может упасть из-за сильного переразгона памяти или нехватки виртуальной памяти.
		; В обоих случаях продолжать тестирование нельзя.
		прерватьТестирование(идУпавшегоПроцесса)
		уведомитьОбОшибке(текстУведомления)
		return
	}

	static найденаОшибка := false
	if not найденаОшибка and dllCall('GetWindowTextLengthW', 'PTR', hwndКоличествоОшибок, 'INT')
	{
		найденаОшибка := true
		if настройки.прерватьТестирование
		{
			текстУведомления := 'TestMem5 нашёл ошибку через ' получитьПрошедшееВремя() '. Тестирование прервано.'
			прерватьТестирование(0)
			уведомитьОбОшибке(текстУведомления)
			return
		}
		уведомитьОбОшибке('TestMem5 нашёл ошибку через ' получитьПрошедшееВремя() '. Тестирование продолжается.')
	}

	if dllCall('GetWindowTextLengthW', 'PTR', hwndИспользованоПамяти, 'INT') == 0
	{
		обработатьКонецТестирования()
	}
}

/**
 * Останавливает рабочий поток главного процесса и убивает все рабочие процессы.
 * Не закрывает главное окно и не убивает главный процесс, чтобы пользователь мог
 * просмотреть результаты тестирования.
 * @param {integer} идУпавшегоПроцесса
 */
прерватьТестирование(идУпавшегоПроцесса)
{
	if идГлавногоПроцесса !== идУпавшегоПроцесса
	{
		найтиПотокиТеста(идГлавногоПроцесса, &идГлавногоПотока, &идРабочегоПотока)
		if идРабочегоПотока
		{
			остановитьПоток(идРабочегоПотока)
		}
	}
	убитьРабочиеПроцессыТеста(идУпавшегоПроцесса)

	; Сменить идентификатор контрола с прошедшим временем на IDC_STATIC, чтобы тест не смог его изменить.
	; Или можно остановить таймер обновления окна, но это значительно сложнее.
	контрол := dllCall('GetDlgItem', 'PTR', hwndГлавноеОкно, 'INT', ИДК_ПРОШЛО_ВРЕМЕНИ, 'PTR')
	dllCall('SetWindowLongW', 'PTR', контрол, 'INT', -12, 'INT', -1, 'INT')

	; Изменить заголовок окна теста, чтобы пользователь понял, почему перестало идти время.
	; Это безопасно даже если процесс теста завис.
	dllCall('SetWindowTextW', 'PTR', hwndГлавноеОкно, 'PTR', strPtr('ТЕСТИРОВАНИЕ ПРЕРВАНО'), 'INT')

	обработатьКонецТестирования()
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

	снимок := dllCall('CreateToolhelp32Snapshot', 'UINT', 4, 'UINT', 0, 'PTR') ; TH32CS_SNAPTHREAD
	данныеПотока := Buffer(28) ; sizeof(THREADENTRY32)
	numPut('UINT', данныеПотока.size, данныеПотока) ; dwSize
	результат := dllCall('Thread32First', 'PTR', снимок, 'PTR', данныеПотока, 'INT')
	while результат
	{
		if numGet(данныеПотока, 12, 'UINT') == идПроцессаТеста ; th32OwnerProcessID
		{
			идПотока := numGet(данныеПотока, 8, 'UINT') ; th32ThreadID
			;@Ahk2Exe-IgnoreBegin
			outputDebug(format('{}: идПотока={}`n', a_ThisFunc, идПотока))
			;@Ahk2Exe-IgnoreEnd
			if поток := dllCall('OpenThread', 'UINT', 0x0800, 'INT', 0, 'UINT', идПотока, 'PTR') ; THREAD_QUERY_LIMITED_INFORMATION
			{
				if dllCall('GetThreadTimes', 'PTR', поток
					, 'INT64*', &времяСоздания := 0, 'INT64*', &времяЗавершения := 0
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
 * Тест плодит кучу рабочих процессов, которые занимаются тестированием памяти. Убить все, кроме упавшего.
 * @param {integer} идУпавшегоПроцесса
 */
убитьРабочиеПроцессыТеста(идУпавшегоПроцесса)
{
	снимок := dllCall('CreateToolhelp32Snapshot', 'UINT', 2, 'UINT', 0, 'PTR') ; TH32CS_SNAPPROCESS
	данныеПроцесса := Buffer(568) ; sizeof(PROCESSENTRY32W)
	numPut('UINT', данныеПроцесса.size, данныеПроцесса) ; dwSize
	результат := dllCall('Process32FirstW', 'PTR', снимок, 'PTR', данныеПроцесса, 'INT')
	while результат
	{
		идПроцесса := numGet(данныеПроцесса, 8, 'UINT') ; th32ProcessID
		if идПроцесса !== идУпавшегоПроцесса
			and numGet(данныеПроцесса, 32, 'UINT') == идГлавногоПроцесса ; th32ParentProcessID
			and strCompare(strGet(данныеПроцесса.ptr + 44), ИМЯ_EXE_ФАЙЛА_ТЕСТА, 'LOCALE') == 0 ; szExeFile
		{
			результат := processClose(идПроцесса)
			;@Ahk2Exe-IgnoreBegin
			outputDebug(format('{}: идПроцесса={} результат={}`n', a_ThisFunc, идПроцесса, результат))
			;@Ahk2Exe-IgnoreEnd
		}
		результат := dllCall('Process32NextW', 'PTR', снимок, 'PTR', данныеПроцесса, 'INT')
	}
	dllCall('CloseHandle', 'PTR', снимок, 'INT')
}

/**
 * @param {string} текстУведомления Этот текст будет записан в журнал и показан во всплывающем уведомлении.
 */
уведомитьОбОшибке(текстУведомления)
{
	записатьВЖурнал(текстУведомления)

	if настройки.проигратьЗвук
	{
		; Стандартный звук винды для сообщения об ошибке.
		soundPlay('*16')
	}

	if настройки.показатьУведомление
	{
		; Всплывающее уведомление в десятой версии винды или пузырь в трее в старых версиях винды.
		; Стандартный значок винды для сообщения об ошибке | уведомление без звука.
		trayTip(текстУведомления,, 3 | 16)
	}

	; Сделать кнопку на панели задач красной.
	try
	{
		; https://www.autohotkey.com/boards/viewtopic.php?t=67431
		taskbarList3 := comObject('{56FDF344-FD6D-11D0-958A-006097C9A090}', '{EA1AFB91-9E28-4B86-90E9-9E9F8A5EEFAF}')
		; ITaskbarList3::SetProgressValue()
		comCall(9, taskbarList3, 'PTR', hwndГлавноеОкно, 'UINT64', 1, 'UINT64', 1)
		; ITaskbarList3::SetProgressState(TBPF_ERROR)
		comCall(10, taskbarList3, 'PTR', hwndГлавноеОкно, 'INT', 4)
	}

	if winExist('A') == hwndГлавноеОкно
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
			dllCall('ShowWindowAsync', 'PTR', hwndГлавноеОкно, 'INT', 4, 'INT')
			; Разместить окно поверх других окон. Полноэкранная игра будет свернута, полноэкранное видео - нет.
			; HWND_TOPMOST, SWP_ASYNCWINDOWPOS | SWP_NOACTIVATE | SWP_NOMOVE | SWP_NOSIZE
			dllCall('SetWindowPos', 'PTR', hwndГлавноеОкно, 'PTR', -1, 'INT', 0, 'INT', 0, 'INT', 0, 'INT', 0
				, 'UINT', 0x4000 | 0x0010 | 0x0002 | 0x0001, 'INT')
			; Разрешить другим окнам перекрывать окно.
			; HWND_NOTOPMOST, SWP_ASYNCWINDOWPOS | SWP_NOACTIVATE | SWP_NOMOVE | SWP_NOSIZE
			dllCall('SetWindowPos', 'PTR', hwndГлавноеОкно, 'PTR', -2, 'INT', 0, 'INT', 0, 'INT', 0, 'INT', 0
				, 'UINT', 0x4000 | 0x0010 | 0x0002 | 0x0001, 'INT')
			; TODO Вызвать SwitchToThread(hwndГлавноеОкно)?
		}
	}

	; TODO Иногда не мигает если найдена ошибка и не открыто других окон.
	if настройки.мигатьЗаголовком
	{
		; Мигать заголовком окна и кнопкой на панели задач пока пользователь не переключится на это окно.
		структура := Buffer(32, 0)
		numPut('UINT', структура.size, структура)
		numPut('PTR', hwndГлавноеОкно, структура, 8)
		; FLASHW_CAPTION | FLASHW_TRAY | FLASHW_TIMERNOFG
		numPut('UINT', 1 | 2 | 12, структура, 16)
		dllCall('FlashWindowEx', 'PTR', структура, 'INT')
	}
}

/**
 * Возвращает количество времени, прошедшее с начала тестирования.
 * @returns {string}
 */
получитьПрошедшееВремя()
{
	прошлоМиллисекунд := a_TickCount - началоТестирования
	return format('{}:{:.2d}', прошлоМиллисекунд // (1000 * 60 * 60), mod(прошлоМиллисекунд // (1000 * 60), 60))
}

/**
 * Записывает указанный текст в файл журнала теста.
 * @param {string} текст Одна строка без завершающих символов `r`n
 */
записатьВЖурнал(текст)
{
	if настройки.ограничитьРазмерЖурнала !== 2
	{
		try
		{
			файл := fileOpen(ПУТЬ_К_ЖУРНАЛУ_ТЕСТИРОВАНИЯ, 'a', 'CP0')
			файл.write(ИМЯ_ПРОГРАММЫ ': ' текст '`r`n')
			файл.close()
		}
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

/**
 * Обработчик событий Menu. Можно вызывать как обычную функцию.
 * @param {string} заголовокОкна
 */
открытьОкноНастроек(заголовокОкна, *)
{
	global окноНастроек
	if isSet(окноНастроек)
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

	;
	; Большая часть имен контролов совпадает с именами свойств переменной |настройки|.
	;
	окноНастроек := Gui(, заголовокОкна)
	окноНастроек.marginX := окноНастроек.marginY := РАЗМЕР_ШРИФТА
	окноНастроек.setFont('S' РАЗМЕР_ШРИФТА, ИМЯ_ШРИФТА)
	окноНастроек.addGroupBox('SECTION R1.5 W' МАКС_ШИРИНА_КОНТРОЛА, 'О программе')
	окноНастроек.addPicture('XP+' ОТСТУП_ГРУППЫ_X ' YP+' ОТСТУП_ГРУППЫ_Y, 'HICON:*' значок)
	окноНастроек.addLink('YP', ИМЯ_ПРОГРАММЫ '   ' ВЕРСИЯ_ПРОГРАММЫ
		. '`r`n' АВТОР_ПРОГРАММЫ '   <a href="' САЙТ_ПРОГРАММЫ '">Сайт программы</a>')
	окноНастроек.addGroupBox('SECTION XS R6 W' МАКС_ШИРИНА_КОНТРОЛА, 'При обнаружении первой ошибки')
	окноНастроек.addCheckBox('VпрерватьТестирование CHECKED' настройки.прерватьТестирование
		. ' XP+' ОТСТУП_ГРУППЫ_X ' YP+' ОТСТУП_ГРУППЫ_Y, 'Прервать тестирование')
		.focus()
	окноНастроек.addCheckBox('VпроигратьЗвук CHECKED' настройки.проигратьЗвук, 'Проиграть звук')
	окноНастроек.addCheckBox('VпоказатьУведомление CHECKED' настройки.показатьУведомление, 'Показать всплывающее уведомление')
	окноНастроек.addCheckBox('VразвернутьОкно CHECKED' настройки.развернутьОкно, 'Переместить окно TestMem5 на передний план')
	окноНастроек.addCheckBox('VмигатьЗаголовком CHECKED' настройки.мигатьЗаголовком, 'Мигать заголовком окна и кнопкой на панели задач')
	окноНастроек.addCheckBox('CHECKED DISABLED', 'Сменить цвет кнопки на панели задач')
	окноНастроек.addGroupBox('XS R3 W' МАКС_ШИРИНА_КОНТРОЛА, 'Что делать с файлами журнала')
	окноНастроек.addRadio('VограничитьРазмерЖурнала SECTION GROUP CHECKED' (настройки.ограничитьРазмерЖурнала == 1)
		. ' XP+' ОТСТУП_ГРУППЫ_X ' YP+' ОТСТУП_ГРУППЫ_Y, 'Удалять Crash.log и урезать Log.txt до')
		.onEvent('CLICK', обработатьИзменениеНастроекЖурнала)
	окноНастроек.addRadio('CHECKED' (настройки.ограничитьРазмерЖурнала == 2), 'Защитить от записи')
		.onEvent('CLICK', обработатьИзменениеНастроекЖурнала)
	окноНастроек.addRadio('CHECKED' (настройки.ограничитьРазмерЖурнала == 3), 'Ничего не делать')
		.onEvent('CLICK', обработатьИзменениеНастроекЖурнала)
	окноНастроек.addEdit('VразмерЖурналаТекст RIGHT NUMBER LIMIT' strLen(МАКС_РАЗМЕР_ЖУРНАЛА)
		. ' YS-3 W' (РАЗМЕР_ШРИФТА * strLen(МАКС_РАЗМЕР_ЖУРНАЛА) + 24))
	окноНастроек.addUpDown('0x80 RANGE' МИН_РАЗМЕР_ЖУРНАЛА '-' МАКС_РАЗМЕР_ЖУРНАЛА, настройки.размерЖурнала)
	окноНастроек.addText('YS', 'КБ')
	окноНастроек.onEvent('ESCAPE', обработатьЗакрытиеОкнаНастроек)
	окноНастроек.onEvent('CLOSE', обработатьЗакрытиеОкнаНастроек)

	обработатьИзменениеНастроекЖурнала()
	; WM_SETICON, ICON_BIG
	sendMessage(0x80, 1, значок, окноНастроек)
	; TODO Открывать окно рядом с треем:
	; controlGetHwnd('TrayNotifyWnd1', 'AHK_CLASS Shell_TrayWnd')
	окноНастроек.show()
}

/**
 * Обработчик событий Gui.Radio. Можно вызывать как обычную функцию.
 */
обработатьИзменениеНастроекЖурнала(*)
{
	окноНастроек['размерЖурналаТекст'].enabled := окноНастроек['ограничитьРазмерЖурнала'].value
}

/**
 * Обработчик событий Gui. Можно вызывать как обычную функцию.
 * Сохраняет измененные настройки в переменной |настройки| и в файле. Уничтожает окно.
 */
обработатьЗакрытиеОкнаНастроек(*)
{
	global окноНастроек

	новыеНастройки := окноНастроек.submit(false)
	новыеНастройки.размерЖурнала := перевестиСтрокуВРазмерЖурнала(новыеНастройки.размерЖурналаТекст)
	for имяНастройки in настройки.ownProps()
	{
		if настройки.%имяНастройки% !== новыеНастройки.%имяНастройки%
		{
			настройки.%имяНастройки% := новыеНастройки.%имяНастройки%
			try iniWrite(новыеНастройки.%имяНастройки%, получитьПутьКФайлуНастроек(), 'настройки', имяНастройки)
		}
	}

	окноНастроек.destroy()
	окноНастроек := unset
}

/**
 * Обработчик onExit().
 */
обработатьЗавершениеПрограммы(*)
{
	global окноНастроек
	if isSet(окноНастроек)
	{
		обработатьЗакрытиеОкнаНастроек()
	}
}
