Number.prototype.hex = function(bytesNum) {
	let result = this.toString(16);
	while(result.length < bytesNum * 2) { result = '0' + result; }
	return result;
}

const arr1 = [1, 1, 2, 3, 4, 5, 6, 7, 8, 0, 0, 0, 0, 0, 0, 0];
const arr2 = [2, 1, 1, 2, 3, 4, 5, 6, 7, 8, 0, 0, 0, 0, 0, 0];
const arr3 = [3, 2, 1, 1, 2, 3, 4, 5, 6, 7, 8, 0, 0, 0, 0, 0];
const arr4 = [4, 3, 2, 1, 1, 2, 3, 4, 5, 6, 7, 8, 0, 0, 0, 0];
const fir = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16];

const result1 = arr1.reduce((acc, value, index) => acc += value * fir[index], 0);
const result2 = arr2.reduce((acc, value, index) => acc += value * fir[index], 0);
const result3 = arr3.reduce((acc, value, index) => acc += value * fir[index], 0);
const result4 = arr4.reduce((acc, value, index) => acc += value * fir[index], 0);

console.log("dataIn: ", Number(4).hex(2), Number(3).hex(2), Number(2).hex(2), Number(1).hex(2));
console.log("dataOut: ", result1.hex(4), result2.hex(4), result3.hex(4), result4.hex(4));
