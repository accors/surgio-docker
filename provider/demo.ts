import { defineCustomProvider, NodeTypeEnum } from 'surgio/project';

export default defineCustomProvider({
  nodeList: [
    {
      nodeName: '🇺🇸US',
      type: NodeTypeEnum.Shadowsocks,
      hostname: 'us.example.com',
      port: '10000',
      method: 'chacha20-ietf-poly1305',
      password: 'password',
      obfs: 'tls',
      obfsHost: 'gateway-carry.icloud.com',
      udpRelay: true,
    },
    {
      nodeName: '🇭🇰HK(Netflix)',
      type: NodeTypeEnum.Shadowsocks,
      hostname: 'hk.example.com',
      port: '10000',
      method: 'chacha20-ietf-poly1305',
      password: 'password',
      udpRelay: true,
    },
  ],
});
