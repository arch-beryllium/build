#!/bin/bash
set -ex
alsaucm -c xiaomiberyllium set _verb HiFi set _enadev HeadPhones
alsaucm -c xiaomiberyllium set _verb HiFi set _enadev Speakers
pulseaudio -k || true
