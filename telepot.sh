#!/usr/bin/env python

import sys
import time
import telepot

import logging
import subprocess
from logging import handlers
from pprint import pprint
import re


reload(sys)
sys.setdefaultencoding('utf8')

def run_shell_command(cmd):
    logger.info("--> cmd line : "+cmd)
    response = ""
    p = subprocess.Popen(cmd, shell=True, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    for line in p.stdout.readlines():
        logger.info("--> output : "+str(line))
        response = response + str(line)
    logger.info("shell response : "+str(response))
    return response


def handle(msg):
    content_type, chat_type, chat_id = telepot.glance(msg)
    #pprint(msg)
    parse = msg['text'].split(' ')
    if len(parse) < 2:
        logger.info("Invalid command")
        return
    passcode = msg['text'][0]
    cmd = msg['text'].split(' ', 1)[1]

    if msg['from']['username'] != admin_username and msg['from']['id'] != admin_uid and passcode == admin_passcode:
        logger.info("un-authorized command from: "+msg['from']['username']+" cmd: "+cmd)
        return

    if content_type == 'text':
        ret = run_shell_command(cmd)
        # max telegram message is 4096
        # https://core.telegram.org/method/messages.sendMessage
        if len(ret) > 4095:
            ret = ret[:4000]+"\n\n...message is truncated..."
        bot.sendMessage(chat_id, cmd+": "+ret)


def check_temperature_room():
    ret = run_shell_command("/usr/local/bin/pcsensor")
    parse = re.split("\s+", ret)
    logger.info(ret)
    if len(parse) > 4:
        temperature = int(float(parse[4].replace("C","")))
        if temperature > max_temperature_room_celcius:
            response = "Room Temperature ALERT !!!\nthreshold:"+str(max_temperature_room_celcius)+"C\n"+ret
            logger.info(response)
            return response
    return ""

def check_temperature_cpu():
    ret = run_shell_command("sensors -u | grep _input | awk '{print $2}' | sort | tail -1")
    temperature = int(float(ret))
    logger.info("highest cpu temperature: "+ret)
    if temperature > max_temperature_cpu_celcius:
        ret = run_shell_command("sensors")
        response = "CPU  Temperature ALERT !!!\nthreshold:"+str(max_temperature_cpu_celcius)+"C\n"+ret
        logger.info(response)
        return response
    return ""


def check_all():
    ret = check_temperature_room()
    if ret != "":
        bot.sendMessage(admin_uid, ret)
    ret = check_temperature_cpu()
    if ret != "":
        bot.sendMessage(admin_uid, ret)
    return





if __name__ == "__main__":

    logger = logging.getLogger(__name__)
    LOG_FORMAT = "%(levelname) -10s %(asctime)s %(name) -15s %(funcName) -20s %(lineno) -5d: %(message)s"
    hdlr = handlers.RotatingFileHandler(filename='<SET THIS:Location of log file>', mode='a', maxBytes=100000000, backupCount=20, encoding='utf8')
    hdlr.setFormatter(logging.Formatter(LOG_FORMAT))
    logging.getLogger().addHandler(hdlr)
    logging.getLogger().setLevel(logging.INFO)

    logger.info("Program started")

    # Adjust this section
    # -----------------------------------------------------------------
    TOKEN="<SET THIS: Your Bot Token>"
    admin_uid = <SET THIS: Your UID, integer, you can get it by uncomment the pprint command inside handle function above>
    admin_username =  "<SET THIS: Your username, string, you can get it by uncomment the pprint command inside handle function above>"
    admin_passcode = "<SET THIS: any single word, does not support space yet>"
    interval = <SET THIS: how frequent you want to run the checking, integer>
    max_temperature_room_celcius = <SET THIS, max threshold for room temperature, integer>
    max_temperature_cpu_celcius = <SET THIS, max threshold for CPU temperature, integer>
    # -----------------------------------------------------------------

    bot = telepot.Bot(TOKEN)
    bot.message_loop(handle)
    print ('Listening ...')
    bot.sendMessage(admin_uid, "bot is started")

    # Keep the program running.
    starttime=int(time.time())
    while 1:
        curtime = int(time.time())
        if curtime - starttime > interval:
            bot.sendMessage(admin_uid, "I am alive")
            check_all()
            starttime=int(time.time())
        time.sleep(10)