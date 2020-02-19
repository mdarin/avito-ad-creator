#!/usr/bin/perl -w 
# 
# Генератор объявлений в формате совместитомом с требованиями сайта 
# Avito.ru для автоматического размещения объявлений
# 
# Created: Сб. нояб. 23 19:00:09 VOLT 2013
# Last updated: 9:54 30.11.2013
my $ver = "0.4b";
# License : GNU GPL >= 2
#  Copyright (C) 2013  Michael DARIN/Михаил ДАРЬИН
#
#  This program is free software; you can redistribute it
#  and/or modify it under the terms of the GNU General
#  Public License as published by the Free Software
#  Foundation; either version 2 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will
#  be useful, but WITHOUT ANY WARRANTY; without even the
#  implied warranty of MERCHANTABILITY or FITNESS FOR A
#  PARTICULAR PURPOSE.  See the GNU General Public License
#  for more details.
#
#  You should have received a copy of the GNU General
#  Public License along with this program; if not, write
#  to the Free Software Foundation, Inc., 675 Mass Ave,
#  Cambridge, MA 02139, USA.
#
#  Michael DARIN may be contacted by email at:
#     m.darin@email.su
#
# Progrogram evalution log
# [*] - новая возможность
# [+] - существующая возможность изменена или доработана
# [-] - возможность изьята и недоступна
# [/] - возможность изьята, но пока доступна  
# [i] - инофрмация
# 0.1b зорождение проекта
# 	* способность читать csv(tsv) и разбирать его по формату(формат не утверждён пока, для пробы)
# 	* генерирование файла xml структуры совместимой с требованиями Avito.ru(не для всех категорий)
# 0.2b готовность для тестирования
#   + генерирование файла xml реализовано для всех категорий кроме "Недвижимость за рубежом"
# 0.3b готовность для тестирования
# 	+ дабавлен анализатор командной строки, реализован пользовательский интерфейс
# 0.4b готовность для тестирования
#   i устранены мелкие недоработки, программа готва для тестирования в реальных условиях
# 	+ доработан пользовательский интерфейс(анализатор командной строки)
# 	+ попытка сделать кроссплатформенное приложение(Windows, Linux)
# TODO:
# 1.Отладить выходной файл до полного соответсвия требованиям Авито
# 2.Обрабатывать более интеллектуально данные заносимые в особо критичные поля Категория и Вид операции
# 3.Придумать что-то с нормализацией полей, перловые средсвтва на кирилке не работают...
# # #
use warnings;
use strict;
use Getopt::Std;
use File::Basename;
use File::Spec;


# Грамматика объявсления
# ----------------------------
# Объявление = Общие атрибуты Атрибуты по категориям.
# Атрибуты по категориям = Комнаты | Квартиры | Дома, дачи, коттеджи 
#             | Земельные частки | Гаражи и стоянки | Коммерческая недвижимость.
# Общие атрибуты объявлений [+] - оздначает обязатеьные поля
# ----------------------------
# Id Уникальный идентификатор объявления [+]
# Category Категория объявления [+]
# DateBegin Дата начала экспозиции объявления
# DateEnd Дата конца экспозиции объявления
# Region Регион, в котором находится объект объявления. [+]
# City Город или населенный пункт, в котором находится объект объявления [+]
# Subway Станция метро
# Description Описание 
# Price Цена в рублях
# ContactPhone Контактный телефон, если не указан, подставляется из данных клиента.
# AdStatus Статус объявления
my $com_attrs = {};

# Атрибуты по категориям
# ----------------------------
# Комнаты
# Category Категория объекта недвижимости [+]
# OperationType Тип объявления [+]
# Locality Город или населенный пункт, уточнение. 
# Street Наименование улицы, на которой находится объект объявления 
# SaleRooms Количество комнат на продажу / сдающихся [+]
# Rooms Количество комнат в квартире [+]
# Square Площадь комнаты (в м.кв.)  [+]
# Floor Этаж, на котором находится объект
# Floors Количество этажей в доме
# HouseType Тип дома
# LeaseType Тип аренды, только для типа "Сдам"
# Images Фотографии объекта
my $room_attrs = {};

# Квартиры 
# Category Категория объекта недвижимости [+] 
# OperationType Тип объявления [+]
# Locality Город или населенный пункт, уточнение. 
# Street Наименование улицы, на которой находится объект объявления 
# Rooms Количество комнат в квартире Для квартиры-студии укажите Студия. [+]
# Square Общая площадь квартиры (в м.кв.) [+]
# Floor Этаж, на котором находится объект
# Floors Количество этажей в доме
# HouseType Тип дома
# MarketType Принадлежность квартиры к рынку новостроек или вторичному, только для типа "Продам" [+]
# LeaseType Тип аренды, только для типа "Сдам" [+]
# Images Фотографии объекта
my $app_attrs = {};

# Дома, дачи, коттеджи
# Category Категория объекта недвижимости [+]
# OperationType Тип объявления [+]
# Locality Город или населенный пункт, уточнение. 
# Street Наименование улицы, на которой находится объект объявления
# Square Площадь дома в м. кв. [+]
# ObjectType Вид объекта [+]
# LandArea Площадь земли в сотках
# DistanceToCity Расстояние до города в км. Примечание: значение 0 означает, что объект находится в черте города.
# WallsType Материал стен
# LeaseType Тип аренды только для типа "Сдам" [+]
# Images Фотографии объекта
my $house_attrs = {};

# Земельные участки 
# Category Категория объекта недвижимости [+]
# OperationType Тип объявления [+]
# Locality Город или населенный пункт, уточнение.
# Street Наименование улицы, на которой находится объект объявления
# LandArea Площадь участка в сотках [+]
# ObjectType Вид земельного участка [+]
# DistanceToCity Расстояние до города в км Примечание: значение 0 означает, что объект находится в черте города. [+]
# Images Фотографии объекта
my $land_attrs = {};

# Гаражи и стоянки 
# Category Категория объекта недвижимости [+]
# OperationType Тип объявления [+]
# Locality Город или населенный пункт, уточнение. 
# Street Наименование улицы, на которой находится объект объявления
# Square Площадь в кв. м. [+]
# ObjectType Вид объекта [+]
# Images Фотографии объекта
my $garage_attrs = {};

# Коммерческая недвижимость
# Category Категория объекта недвижимости [+]
# ObjectType Вид объекта [+]
# BusinessForSale Объект является готовым бизнесом Только для типа "Продам"
# OperationType Тип объявления [+]
# Locality Город или населенный пункт, уточнение. 
# Street Наименование улицы, на которой находится объект объявления
# Square Площадь помещения в м.кв. [+]
# Images Фотографии объекта
my $com_realty_attrs = {};


# __debug
#while (my($attr, $value) =each %$com_attrs) {
	#print "key: $attr - value: $value\n";
#	$com_attrs->{$attr} = $value;
#	print " * $com_attrs->{$attr}\n";
	#int (rand (10000))
#}

my $usage = "Usage: crad [-cv] src.csv [-o dst.xml]\n\t-c - enable convertation to utf8\n\t-o - output xml file name and path\n\t-v - show version\n";

die $usage
	if (1 > @ARGV);

my $option = {};

getopts("i:o:cv", $option);

if ($option->{v}) {
	print "crad - GNU create Avito advertisement\nversion: $ver\n(c)2013 Michael DARIN\n";
	exit 0;
}

if ($option->{o}) {
	print "Output file: $option->{o}\n";
}

my $cflag = 0;
if ($option->{c}) {
	print "Convertation enabled\n";
	$cflag = 1;
}

my $src_fname = shift @ARGV;
my $dst_fname = $option->{o} || "$1.xml" if $src_fname =~ m/(.+?)\..+$/g;
$dst_fname = "$dst_fname.xml"
	unless ($dst_fname =~ m/(\.xml)$/);
my $separator = ";";

print "Source CSV file: $src_fname\nDest XML file: $dst_fname\n";

open my $fin, "<$src_fname"
	or die "Can't open $src_fname file: $!";
#">:encoding(UTF-8)"
open my $fout, ">$dst_fname"
	or die "Can't open $dst_fname file: $!";
# Формат записи в БД для Комнаты и Квартиры (Будет пересмотрен сейчас это заблуждение, годное только на бету)
# Поз	№пп	Наим	Описание
#	0	1 Id	Уникальный идентификатор объявления
# 1	2	Category	Категория объявления
# 2	3 DateBegin	Дата начала экспозиции объявления
# 3	4 DateEnd	Дата конца экспозиции объявления
# 4 5 Region	Регион, в котором находится объект объявления
# 5	6 City	Город или населенный пункт, в котором находится объект объявления
# 6	7 Subway	Станция метро
# 7	8 Description	Описание
# 8	9 Price	Цена в рублях
# 9	10 ContactPhone	Контактный телефон
# 10	11 AdStatus	 Статус объявления
# 11	12 OperationType	Тип объявления
# 12	13 Locality	Город или населенный пункт, уточнение
# 13	14 Street	Наименование улицы, на которой находится объект объявления
# 14	15 SaleRooms	Количество комнат на продажу / сдающихся
# 15	16 Rooms	Количество комнат в квартире
# 16	17 Square	Площадь (в м.кв.)
# 17	18 Floor	Этаж, на котором находится объект
# 18	19 Floors	Количество этажей в доме
# 19	20 HouseType	Тип дома
# 20	21 LeaseType	Тип аренды только для типа "Сдам"
# 21	22 Images	Фотографии объекта
# 22	23 MarketType	Принадлежность квартиры к рынку новостроек или вторичному, только для типа "Продам" 
# 23	24 ObjectType	Вид объекта
# 24	25 LandArea	Площадь земли в сотках
# 25	26 DistanceToCity	Расстояние до города в км.
# 26	27 WallsType	Материал стен
# 27	28 BusinessForSale Объект является готовым бизнесом Только для типа "Продам"

# вывести заголовок xml файла объявлений
print $fout "\<\?xml version=\"1.0\" encoding=\"UTF-8\" \?\>\n";
print $fout "\<Ads target\=\"Avito\.ru\" formatVersion\=\"1\"\>\n";
# Получить список атрибутов
my $line = <$fin>;
chomp ($line);
my $attrs_list = [split /$separator/, $line];
# Выделить наименования атрибутов
foreach my $i (0..@$attrs_list-1) {
	if ($attrs_list->[$i] =~ m/(\w+)/ ) {
		#print " * [$1]\n";
		$attrs_list->[$i] = $1;
	}
}

print "Generatig xml file...\n";

#------------------------------------------------------------------------------
#The \U escape forces what follows to all uppercase:
#$_ = "I saw Barney with Fred.";
#s/(fred|barney)/\U$1/gi; # $_ is now "I saw BARNEY with FRED."
#Similarly, the \L escape forces lowercase. Continuing from the previous code:
#s/(fred|barney)/\L$1/gi;
# $_ is now "I saw barney with fred."

# Пропустить шапку
$line = <$fin>;
# Читать файл построчноî
while ($line = <$fin>) {
	print $fout "\t<Ad>\n";
	chomp $line;
	my $record = [split /$separator/, $line];
	# Id Уникальный идентификатор объявления [+]
	# Category Категория объявления [+]
	# DateBegin Дата начала экспозиции объявления
	# DateEnd Дата конца экспозиции объявления
	# Region Регион, в котором находится объект объявления. [+]
	# City Город или населенный пункт, в котором находится объект объявления [+]
	# Subway Станция метро
	# Description Описание 
	# Price Цена в рублях
	# ContactPhone Контактный телефон, если не указан, подставляется из данных клиента.
	# AdStatus Статус объявления
	$com_attrs->{'Id'} = $record->[0] if ('' ne $record->[0]);
	$com_attrs->{'Category'} =  $record->[1] if ('' ne $record->[1]);
	$com_attrs->{'DateBegin'} = $record->[2] if ('' ne $record->[2]);  
 	$com_attrs->{'DateEnd'} = $record->[3] if ('' ne $record->[3]);
	$com_attrs->{'Region'} = $record->[4] if ('' ne $record->[4]);
	$com_attrs->{'City'} = $record->[5] if ('' ne $record->[5]);
	$com_attrs->{'Subway'} = $record->[6] if ('' ne $record->[6]);
	$com_attrs->{'Description'} = $record->[7] if ('' ne $record->[7]);
	$com_attrs->{'Price' } = $record->[8] if ('' ne $record->[8]);
	$com_attrs->{'ContactPhone'} = $record->[9] if ('' ne $record->[9]);
	$com_attrs->{'AdStatus'} = $record->[10] if ('' ne $record->[10]);

	# Нормлизовать поле
	#$com_attrs->{'Category'} ... \L\u$name\E работает только с латинкой...

	&print_cat_attrs ($fout, $com_attrs);
	# В зависимости от категории заполнить и вывести соответсвующие атрибуты
	# Атрибут Категория(Category) для специфических атрибутов не заполняется, он 
	# заполняется в общих атрибутах(в доке он фигурироует в обеих группах :))
	if ( $com_attrs->{'Category'} =~ m/(Комнаты)/gi ) {
		# Комнаты
		# Category Категория объекта недвижимости [+]
		# OperationType Тип объявления [+]
		# Locality Город или населенный пункт, уточнение. 
		# Street Наименование улицы, на которой находится объект объявления 
		# SaleRooms Количество комнат на продажу / сдающихся [+]
		# Rooms Количество комнат в квартире [+]
		# Square Площадь комнаты (в м.кв.)  [+]
		# Floor Этаж, на котором находится объект
		# Floors Количество этажей в доме
		# HouseType Тип дома
		# LeaseType Тип аренды, только для типа "Сдам"
		# Images Фотографии объекта
		$room_attrs->{'OperationType'} = $record->[11] if ('' ne $record->[11]);
		$room_attrs->{'Locality'} = $record->[12] if ('' ne $record->[12]);
		$room_attrs->{'Street'} = $record->[13] if ('' ne $record->[13]);
		$room_attrs->{'SaleRooms'} = $record->[14] if ('' ne $record->[14]);
		$room_attrs->{'Rooms'} = $record->[15] if ('' ne $record->[15]);
		$room_attrs->{'Square'} = $record->[16] if ('' ne $record->[17]);
		$room_attrs->{'Floor'} = $record->[17] if ('' ne $record->[18]);
		$room_attrs->{'Floors'} = $record->[18] if ('' ne $record->[19]);
		$room_attrs->{'HouseType'} = $record->[19] if ('' ne $record->[19]);
		if ($room_attrs->{'OperationType'} =~ m/(Сдам)/gi ) {
			$room_attrs->{'LeaseType'} = $record->[20] if ('' ne $record->[20]);
		}
		$room_attrs->{'Images'} = $record->[21] if ('' ne $record->[21]);
		&print_cat_attrs ($fout, $room_attrs);
	} elsif( $com_attrs->{'Category'} =~ m/(Квартиры)/gi ) {
		# Квартиры 
		# Category Категория объекта недвижимости [+] 
		# OperationType Тип объявления [+]
		# Locality Город или населенный пункт, уточнение. 
		# Street Наименование улицы, на которой находится объект объявления 
		# Rooms Количество комнат в квартире Для квартиры-студии укажите Студия. [+]
		# Square Общая площадь квартиры (в м.кв.) [+]
		# Floor Этаж, на котором находится объект
		# Floors Количество этажей в доме
		# HouseType Тип дома
		# MarketType Принадлежность квартиры к рынку новостроек или вторичному, только для типа "Продам" [+]
		# LeaseType Тип аренды, только для типа "Сдам" [+]
		# Images Фотографии объекта
		$app_attrs->{'OperationType'} = $record->[11] if ('' ne $record->[11]);
		$app_attrs->{'Locality'} = $record->[12] if ('' ne $record->[12]);
		$app_attrs->{'Street'} = $record->[13] if ('' ne $record->[13]);
		$app_attrs->{'Rooms'} = $record->[15] if ('' ne $record->[15]);
		$app_attrs->{'Square'} = $record->[16] if ('' ne $record->[16]);
		$app_attrs->{'Floor'} = $record->[17] if ('' ne $record->[17]);
		$app_attrs->{'Floors'} = $record->[18] if ('' ne $record->[18]);
		$app_attrs->{'HouseType'} = $record->[19] if ('' ne $record->[19]);
		if ( $app_attrs->{'OperationType'} =~ m/(Продам)/gi ) {
			$app_attrs->{'MarketType'} = $record->[22] if ('' ne $record->[22]);
		} elsif ( $app_attrs->{'OperationType'} =~ m/(Сдам)/gi ) {
			$app_attrs->{'LeaseType'} = $record->[20] if ('' ne $record->[20]);
		}		
		$app_attrs->{'Images'} = $record->[21] if ('' ne $record->[21]);
		&print_cat_attrs ($fout, $app_attrs);
	} elsif($com_attrs->{'Category'} =~ m/(Дома,\s*дачи,\s*коттеджи)/gi ) {
		# Дома, дачи, коттеджи
		# Category Категория объекта недвижимости [+]
		# OperationType Тип объявления [+]
		# Locality Город или населенный пункт, уточнение. 
		# Street Наименование улицы, на которой находится объект объявления
		# Square Площадь дома в м. кв. [+]
		# ObjectType Вид объекта [+]
		# LandArea Площадь земли в сотках
		# DistanceToCity Расстояние до города в км. Примечание: значение 0 означает, что объект находится в черте города.
		# WallsType Материал стен
		# LeaseType Тип аренды только для типа "Сдам" [+]
		# Images Фотографии объекта
		$house_attrs->{'OperationType'} = $record->[11] if ('' ne $record->[11]);
		$house_attrs->{'Locality'} = $record->[12] if ('' ne $record->[12]);
		$house_attrs->{'Street'} = $record->[13] if ('' ne $record->[13]);
		$house_attrs->{'Square'} = $record->[16] if ('' ne $record->[16]);
		$house_attrs->{'ObjectType'} = $record->[23] if ('' ne $record->[23]);
		$house_attrs->{'LandArea'} = $record->[24] if ('' ne $record->[24]);
		$house_attrs->{'DistanceToCity'} = $record->[25] if ('' ne $record->[25]);
		$house_attrs->{'WallsType'} = $record->[26] if ('' ne $record->[26]);
		if ($house_attrs->{'OperationType'} =~ m/(Сдам)/gi ) {
			$house_attrs->{'LeaseType'} = $record->[20] if ('' ne $record->[20]);
		}		
		$house_attrs->{'Images'} = $record->[21] if ('' ne $record->[21]);
		&print_cat_attrs ($fout, $house_attrs);
	} elsif($com_attrs->{'Category'} =~ m/(Земельные участки)/gi ) {
		# Земельные участки
		# Category Категория объекта недвижимости [+]
		# OperationType Тип объявления [+]
		# Locality Город или населенный пункт, уточнение.
		# Street Наименование улицы, на которой находится объект объявления
		# LandArea Площадь участка в сотках [+]
		# ObjectType Вид земельного участка [+]
		# DistanceToCity Расстояние до города в км Примечание: значение 0 означает, что объект находится в черте города. [+]
		# Images Фотографии объекта
		$land_attrs->{'OperationType'} = $record->[11] if ('' ne $record->[11]);
		$land_attrs->{'Locality'} = $record->[12] if ('' ne $record->[12]);
		$land_attrs->{'Street'} = $record->[13] if ('' ne $record->[13]);
		$land_attrs->{'ObjectType'} = $record->[23] if ('' ne $record->[23]);
		$land_attrs->{'LandArea'} = $record->[24] if ('' ne $record->[24]);
		$land_attrs->{'DistanceToCity'} = $record->[25] if ('' ne $record->[25]);
		$land_attrs->{'Images'} = $record->[21] if ('' ne $record->[21]);
		&print_cat_attrs ($fout, $land_attrs);
	} elsif($com_attrs->{'Category'} =~ m/(Гаражи\s*и\s*стоянки)/gi ) {
		# Гаражи и стоянки
		# Category Категория объекта недвижимости [+]
		# OperationType Тип объявления [+]
		# Locality Город или населенный пункт, уточнение. 
		# Street Наименование улицы, на которой находится объект объявления
		# Square Площадь в кв. м. [+]
		# ObjectType Вид объекта [+]
		# Images Фотографии объекта
		$garage_attrs->{'OperationType'} = $record->[11] if ('' ne $record->[11]);
		$garage_attrs->{'Locality'} = $record->[12] if ('' ne $record->[12]);
		$garage_attrs->{'Street'} = $record->[13] if ('' ne $record->[13]);
		$garage_attrs->{'ObjectType'} = $record->[23] if ('' ne $record->[23]);
		$garage_attrs->{'Square'} = $record->[16] if ('' ne $record->[16]);
		$garage_attrs->{'Images'} = $record->[21] if ('' ne $record->[21]);
		&print_cat_attrs ($fout, $garage_attrs);
	} elsif($com_attrs->{'Category'} =~ m/(Коммерческая\s*недвижимость)/gi ) {
		# Коммерческая недвижимость
		# Category Категория объекта недвижимости [+]
		# ObjectType Вид объекта [+]
		# BusinessForSale Объект является готовым бизнесом Только для типа "Продам"
		# OperationType Тип объявления [+]
		# Locality Город или населенный пункт, уточнение. 
		# Street Наименование улицы, на которой находится объект объявления
		# Square Площадь помещения в м.кв. [+]
		# Images Фотографии объекта
		$com_realty_attrs->{'OperationType'} = $record->[11] if ('' ne $record->[11]);
		$com_realty_attrs->{'Locality'} = $record->[12] if ('' ne $record->[12]);
		$com_realty_attrs->{'Street'} = $record->[13] if ('' ne $record->[13]);
		$com_realty_attrs->{'ObjectType'} = $record->[23] if ('' ne $record->[23]);
		$com_realty_attrs->{'Square'} = $record->[16] if ('' ne $record->[16]);
		$com_realty_attrs->{'Images'} = $record->[21] if ('' ne $record->[21]);
		if ($com_realty_attrs->{'OperationType'} =~ m/(Продам)/gi ) {
			$com_realty_attrs->{'BusinessForSale'} = $record->[27] if ('' ne $record->[27]);
		}
		&print_cat_attrs ($fout, $com_realty_attrs);
	}
	print $fout "\t</Ad>\n";
}
print $fout "</Ads>\n";
close $fin;
close $fout;

# Если конвертация выходного файла в utf8 влючена  
# то вызвать программу для конвертирования 
# только для Windows MS Office: win_iconv.exe
# Для Linux это просто не нужно только надо использовать кодировку utf8
if ($cflag) {
	my ($fname, undef,$fext) = $dst_fname =~ m/(.+?)(\.(.+))$/gi;
	my $new_dst_fname = "$fname.utf8.$fext";
	my $dirname = dirname $0;
	my $iconv_path = File::Spec->catfile($dirname, "win_iconv.exe");	
	my $iconv_args = "-f CP1251 -t UTF-8 \"$dst_fname\" >\"$new_dst_fname\"";
	print `"$iconv_path" $iconv_args`;
	unlink $dst_fname;
}

print "Generating xml file has done!\n";

sub print_cat_attrs {
	my ($fout, $attrs) = @_;
	while (my($attr, $value) =each %$attrs) {
		if (exists $attrs->{$attr}) {
			if ( $attr eq 'Images' ) {
				my $imgs = [$value =~ m/(.+?\..+?)\s*/gi];
				print $fout "\t\t<$attr>\n";
				foreach my $img (@$imgs) {
					print $fout "\t\t\t<Image name=\"$img\"/>\n";
				}
				print $fout "\t\t</$attr>\n";
			} else {
				print $fout "\t\t<$attr>$value</$attr>\n";
			}
		}
	}
}


