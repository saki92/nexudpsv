WL_CHANSPEC_BW_20 = uint32(hex2dec('1000'));
WL_CHANSPEC_BW_40 = uint32(hex2dec('1800'));
WL_CHANSPEC_BW_80 = uint32(hex2dec('2000'));

WL_CHANSPEC_BAND_2G = uint32(hex2dec('0000'));
WL_CHANSPEC_BAND_5G = uint32(hex2dec('c000'));

RATES_RATE_6M  = 12;
RATES_RATE_9M  = 18;
RATES_RATE_12M = 24;
RATES_RATE_18M = 36;
RATES_RATE_24M = 48;
RATES_RATE_36M = 72;
RATES_RATE_48M = 96;
RATES_RATE_54M = 108;

RATES_RATE = [
    RATES_RATE_6M;
    RATES_RATE_9M;
    RATES_RATE_12M;
    RATES_RATE_18M;
    RATES_RATE_24M;
    RATES_RATE_36M;
    RATES_RATE_48M;
    RATES_RATE_54M;
];
start_offset = 1500*4;

normalize = @(sig) sig/sqrt(sum(sum(abs(sig).^2))/numel(sig));

ieeeenc = ieee_80211_encoder();
ieeeenc.set_rate(1);

mac_packet = [ ...
    '80000000ffffffffffff827bbef096e0827bbef096e0602f54e02a09000000006' ...
    '4001111000f4d79436f766572744368616e6e656c01088c129824b048606c0504' ...
    '0103000007344445202401172801172c01173001173401173801173c011740011' ...
    '764011e68011e6c011e70011e74011e84011e88011e8c011e0020010023021300' ...
    '30140100000fac040100000fac040100000fac0200002d1aef0917ffffff00000' ...
    '000000000000000000000000000000000003d16280f0400000000000000000000' ...
    '0000000000000000007f080000000000000040bf0cb259820feaff0000eaff000' ...
    '0c005012a000000c30402020202dd0700039301770208dd0e0017f20700010106' ...
    '80ea96f0be7bdd090010180200001c0000dd180050f2020101800003a4000027a' ...
    '4000042435e0062322f0046050200010000ce9405ef' ];
mac_data = reshape(de2bi(hex2dec(mac_packet'),4,'left-msb')',1,[]);

ltf_format = 'LTF';

[time_domain_signal_struct, encoded_bit_vector, symbols_tx_mat] = ...
    ieeeenc.create_standard_frame(mac_data, 0, 'LTF', [], [], []);
tx_signal = time_domain_signal_struct.tx_signal;

tx_signal = normalize(tx_signal)*10^(-11/20);

%%
m = 10000;
tx_signal_nexmon = [ ...
    zeros(1,1000,'int32') ...
    bitor(bitshift(bitand(int32(real(tx_signal) * m), hex2dec('ffff')), 16), bitand(int32(imag(tx_signal) * m), hex2dec('ffff'))) ...
    zeros(1,1000,'int32')
];

tx_signal_nexmon_hdr = [ ...
    int32((0:80-1)*4*259); ...
    repmat(int32(259 * 4),1,80); ...
    reshape(tx_signal_nexmon, 259, 80) ...
];

tx_settings = [ ...
    %uint32(bitor(bitor(WL_CHANSPEC_BW_20, WL_CHANSPEC_BAND_5G), uint32(106))); % chanspec
    uint32(bitor(bitor(WL_CHANSPEC_BW_20, WL_CHANSPEC_BAND_2G), uint32(1))); % chanspec
    int32(start_offset/4); % start_offset in samples (4 bytes each)
    int32(length(tx_signal)); % number of samples
    uint32(RATES_RATE(1)); % rate to transmit real ack after raw ack
];

udpr = dsp.UDPReceiver('LocalIPPort',31000);
udpsl = dsp.UDPSender('RemoteIPPort',31000);
%udps = dsp.UDPSender('RemoteIPAddress','192.168.1.1','RemoteIPPort',99);
% To prevent the loss of packets, call the |setup| method
% on the object before the first call to the |step| method.
%setup(udpr); 

bytesSent = 0;
bytesReceived = 0;
dataLength = 1048;

for k = 1:80
   %dataSent = uint32(104);
   %dataSent = [uint16(711);uint16(1500);uint32(tx_signal_nexmon_hdr(:,k))];
   %dataSent = uint32([uint32(bin2dec(dec2bin('nexutil -g711 -b -l1500 -v%s\n',32)));matlab.net.base64encode(typecast(tx_signal_nexmon_hdr(:,k),'uint8'))';uint32(bin2dec(dec2bin('\n',32)))]);
   dataSent = uint32([711;1500;tx_signal_nexmon_hdr(:,k)]);
   bytesSent = bytesSent + dataLength;
   udpsl(dataSent);
   %udps(dataSent);
   %dataReceived = udpr();
   %bytesReceived = bytesReceived + length(dataReceived);
end

release(udpsl);
release(udpr);

fprintf('Bytes sent:     %d\n', bytesSent);

% fileID = fopen('sine.sh','w');
% for i=1:80
%     fprintf(fileID, 'nexutil -s711 -b -l1500 -v%s\n', matlab.net.base64encode(typecast(tx_signal_nexmon_hdr(:,i),'uint8')));
% end
% fprintf(fileID, 'nexutil -g713 -b -l16 -v%s\n', matlab.net.base64encode(typecast(tx_settings,'uint8')));
% fclose(fileID);