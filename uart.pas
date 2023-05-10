unit uart;

interface

// Specify baud rate via command line define BAUD
// If BAUD is not defined, it will default to 115200 if hardware UART is used,
// else if will default to 9600 for software UART
procedure uart_init;

// Blocking functions
procedure uart_transmit(const data: byte); overload;
function uart_receive: byte;

implementation

//{$I uartconsts.inc}

{$ifndef BAUD}
  {$define BAUD:=115200}
{$endif}
procedure uart_init;
const
  UBRRValue = (((F_CPU + 4*BAUD) shr 3) div BAUD)-1;
begin
  UBRR0H := UBRRValue shr 8;
  UBRR0L := byte(UBRRValue);

  // Set U2X bit
  UCSR0A := (1 shl U2X0);

  // Enable receiver and transmitter
  UCSR0B := (1 shl RXEN0) or (1 shl TXEN0);

  // Set frame format: 8data, 1stop bit, no parity
  UCSR0C := (3 shl UCSZ0);
end;

procedure uart_transmit(const data: byte);
begin
  // Wait for empty transmit buffer
  while ((UCSR0A and (1 shl UDRE0)) = 0) do;

  // Put data into buffer, sends the data
  UDR0 := data;
end;

function uart_receive: byte;
begin
  // Wait for data to be received
  while ((UCSR0A and (1 shl RXC0)) = 0) do;

  // Get and return received data from buffer
  result := UDR0;
end;

end.
