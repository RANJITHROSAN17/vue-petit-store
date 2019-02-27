const is_windows = process.platform==='win32'
const is_mac = process.platform==='darwin'
const is_linux = process.platform==='linux'

module.exports = { is_windows, is_mac, is_linux }
