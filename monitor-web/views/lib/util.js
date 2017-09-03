function log(){
    console.log.apply(console, arguments);
}
//扩展Date的format方法
Date.prototype.format = function (format) {
	var o = {
		"M+": this.getMonth() + 1,
		"d+": this.getDate(),
		"h+": this.getHours(),
		"m+": this.getMinutes(),
		"s+": this.getSeconds(),
		"q+": Math.floor((this.getMonth() + 3) / 3),
		"S+": this.getMilliseconds()
	}
	if (/(y+)/.test(format)) {
		format = format.replace(RegExp.$1, (this.getFullYear() + "").substr(4 - RegExp.$1.length));
	}
	for (var k in o) {
		if (new RegExp("(" + k + ")").test(format)) {
			var replaceWith;
			if (RegExp.$1.length == 1)
				replaceWith = o[k];
			else if (k == "S+")
				replaceWith = ("000" + o[k]).substr(("" + o[k]).length);
			else
				replaceWith = ("00"  + o[k]).substr(("" + o[k]).length);
			format = format.replace(RegExp.$1, replaceWith);
		}
	}
	return format;
}

/**
 * inputDateStr 必须与 inputFormat 一一对应且等长
 *  yyyy-MM-dd hh:mm:ss
 * @param inputDateStr
 * @param inputFormat
 * @returns {Date}
 */
function strToDate(inputDateStr, inputFormat) {
	var cur = new Date();
	var obj = {
		y: cur.getYear(),
		M: 1,
		d: 1,
		h: 0,
		m: 0,
		s: 0,
		S: 0
	};

	// 预处理, 删除format 中 yMdhmsS 之外的字符, 同时删除str对应的字符
	var str = "";
	var format = "";
	for (var i=0; i<inputFormat.length; ++i) {
		if ("yMdhmsS".indexOf(inputFormat.charAt(i)) >= 0) {
			str += inputDateStr[i];
			format += inputFormat[i];
		}
	}

	var startIdx=0, endIdx;
	while (startIdx < format.length) {
		var startChar = format.charAt(startIdx);
		endIdx = startIdx+1;
		while (endIdx < format.length && format.charAt(endIdx) == startChar)
			++endIdx;

		obj[startChar] = parseInt(str.substring(startIdx, endIdx));

		startIdx = endIdx;
	}

	return new Date(obj.y, obj.M - 1, obj.d, obj.h, obj.m, obj.s, obj.S);
}

/**
 *转换日期对象为日期字符串
 * @param date 日期对象
 * @param isFull 是否为完整的日期数据,
 *               为true时, 格式如"2000-03-05 01:05:04"
 *               为false时, 格式如 "2000-03-05"
 * @return 符合要求的日期字符串
 */
function getSmpFormatDate(date, isFull) {
	var pattern = "";
	if (isFull == true || isFull == undefined) {
		pattern = "yyyy-MM-dd hh:mm:ss";
	} else {
		pattern = "yyyy-MM-dd";
	}
	return getFormatDate(date, pattern);
}
/**
 *转换当前日期对象为日期字符串
 * @param date 日期对象
 * @param isFull 是否为完整的日期数据,
 *               为true时, 格式如"2000-03-05 01:05:04"
 *               为false时, 格式如 "2000-03-05"
 * @return 符合要求的日期字符串
 */

function getSmpFormatNowDate(isFull) {
	return getSmpFormatDate(new Date(), isFull);
}
/**
 *转换long值为日期字符串
 * @param l long值
 * @param isFull 是否为完整的日期数据,
 *               为true时, 格式如"2000-03-05 01:05:04"
 *               为false时, 格式如 "2000-03-05"
 * @return 符合要求的日期字符串
 */

function getSmpFormatDateByLong(l, isFull) {
	return getSmpFormatDate(new Date(l), isFull);
}
/**
 *转换long值为日期字符串
 * @param l long值
 * @param pattern 格式字符串,例如：yyyy-MM-dd hh:mm:ss
 * @return 符合要求的日期字符串
 */

function getFormatDateByLong(l, pattern) {
	return getFormatDate(new Date(l), pattern);
}
/**
 *转换日期对象为日期字符串
 * @param l long值
 * @param pattern 格式字符串,例如：yyyy-MM-dd hh:mm:ss
 * @return 符合要求的日期字符串
 */
function getFormatDate(date, pattern) {
	if (date == undefined) {
		date = new Date();
	}
	if (pattern == undefined) {
		pattern = "yyyy-MM-dd hh:mm:ss";
	}
	return date.format(pattern);
}

