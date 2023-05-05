unit uart;

interface

// Automatically use U2X
// Calculate UBRR value as follows:
//   UBRRValue = (((F_CPU + 4*BAUD) shr 3) div BAUD)-1;
procedure uart_init(const UBRR: word);

// Blocking functions
procedure uart_transmit(const data: byte); overload;
function uart_receive: byte;

implementation

{$I uartconsts.inc}

procedure uart_init(const UBRR: word);
begin
  xUBRR0H := UBRR shr 8;
  xUBRR0L := byte(UBRR);

  // Set U2X bit
  xUCSR0A := xUCSR0A or (1 shl xU2X0);

  // Enable receiver and transmitter
  xUCSR0B := (1 shl xRXEN0) or (1 shl xTXEN0);

  // Set frame format: 8data, 1stop bit, no parity
  xUCSR0C := (1 shl xURSEL0) or (3 shl xUCSZ0);
end;

procedure uart_transmit(const data: byte);
begin
  // Wait for empty transmit buffer
  while ((xUCSR0A and (1 shl xUDRE0)) = 0) do;

  // Put data into buffer, sends the data
  xUDR0 := data;
end;

function uart_receive: byte;
begin
  // Wait for data to be received
  while ((xUCSR0A and (1 shl xRXC0)) = 0) do;

  // Get and return received data from buffer
  result := xUDR0;
end;

end.
