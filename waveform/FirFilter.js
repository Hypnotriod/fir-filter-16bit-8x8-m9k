Number.prototype.hex = function(bytesNum) {
	let result = (this >>> 0).toString(16);
	while (result.length < bytesNum * 2) { result = '0' + result; }
	if (result.length > bytesNum * 2) result = result.slice(-bytesNum * 2);
	return result;
}

const buff = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32];
const fir = [-1, 12, 18, 17, 9, 0, -4, -1, 5, 6, 0, -13, -26, -36, -40, -43, -47, -52, -50, -41, -24, -5, 6, 8, 1, -8, -12, -7, 1, 10, 15, 14];

const input = [1, 2, 3, 4, 1, 2, 3, 4, 1, 2, 3, 4];
const result = [];

const filter = (arr) => (acc, value, index) => acc += value * arr[index];

input.forEach(v => {
	buff.pop();
	buff.unshift(v);
	result.push(fir.reduce(filter(buff), 0));
});

console.log("dataIn: ", input.reduce((acc, v) => acc += v + ', ', ''));
console.log("dataFir: ", fir.reduce((acc, v) => acc += v + ', ', ''));
console.log("dataOut: ", result.reduce((acc, v) => acc += v.hex(4) + ' ', ''));
