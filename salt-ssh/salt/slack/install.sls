
Install deb slack package:
  pkg.installed:
    - sources:
      - slackDebPkg: salt://files/deb/{{ pillar['slackDeb'] }}
    - onlyif:
      - fun: match.grain
        tgt: 'os_family:Debian'
    - unless:
      - dpkg -l slack-desktop

Install rpm slack package:
  pkg.installed:
    - sources:
      - slackRpmPkg: salt://files/rpm/{{ pillar['slackRpm'] }}
    - onlyif:
      - fun: match.grain
        tgt: 'os_family:RedHat'
    - unless:
      - rpm -q slack-desktop
