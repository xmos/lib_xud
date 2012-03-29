/*
 * Copyright XMOS Limited - 2009
 * 
 * An example testbench which instantiates one simulator and connects pairs of pins.
 *
 */

#include <string>
#include <vector>
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include "xsidevice.h"
using namespace std;
#include "crc.h"
#include "test.h"


/* TODO List*/
/*
 * - Ideally RXA done properly - requires two more states using RxAStartDelay and RxAEndDelay
 * - RxV bubbles in packets
 * - USB clock not right - currently /17
 */

#define PID_OUT   1
#define PID_ACK   2
#define PID_DATA0 3
#define PID_IN    9

#define PIDn_ACK     0xd2
#define PIDn_DATA0   0xC3


#define MAX_INSTANCES 256

/* All port names relative to Xcore */
#define CLK_PORT        "XS1_PORT_1J"

#define RX_DATA_PORT    "XS1_PORT_8C"

#define RX_RXA_PORT     "XS1_PORT_1O" // FLAG 1

#define RX_RXV_PORT     "XS1_PORT_1M"

#define V_TOK_PORT      "XS1_PORT_1N" 

#define TX_DATA_PORT    "XS1_PORT_8A"
#define TX_RDY_OUT_PORT "XS1_PORT_1K"
#define TX_RDY_IN_PORT "XS1_PORT_1H"


using namespace std;

typedef enum USBEventType { tx, rx, delay, tok, };

typedef struct testnode                                                
{                                                               
      int data;               // will store information
      testnode *next;             // the reference to the next node
}; 

class USBEvent
{
    protected:
        USBEventType eventType;

    public:
        USBEvent();
        USBEvent (USBEventType e) {eventType = e;}  // Contructor
        USBEventType GetEventType() {return eventType;}
        virtual int GetDelayTime(){return 9999999;}
};


class USBDelay: public USBEvent 
{
    protected:
        int delayTime;

    public:
        USBDelay();
        USBDelay(int d):USBEvent(delay) {delayTime = d;}// Contstructor
        int GetDelayTime() {return delayTime;}
};

class USBRxPacket: public USBEvent 
{
    protected:
        int dataLength;
        unsigned char *data;

    public:
        USBRxPacket();
        USBRxPacket(int l, unsigned char *d):USBEvent(rx) {dataLength = l;data=d;}// Contstructor
        int GetDataLength() {return dataLength;}
        int GetData(int i) {return data[i];}
};

class USBRxToken: public USBEvent 
{
    protected:
        unsigned char pid;
        unsigned char ep;

    public:
        USBRxToken();
        USBRxToken(unsigned char p, unsigned char e):USBEvent(tok) {pid = p; ep=e;}// Contstructor
        int GetPid() {return pid;}
        int GetEp() {return ep;}
};

class USBTxPacket: public USBEvent 
{
    protected:
        int dataLength; // Expected
        unsigned char *data;  // Expected
        int timeout;          


    public:
        USBTxPacket();
        USBTxPacket(int l, unsigned char *d, int t):USBEvent(tx) {dataLength = l;data=d;timeout=t;}// Contstructor
        int GetDataLength() {return dataLength;}
        int GetData(int i) {return data[i];}
        int GetTimeout() {return timeout;}
};





typedef struct node                                                
{                                                               
      USBEvent *e;               // will store information
      node *next;             // the reference to the next node
};  

void *g_device = 0;
string g_sim_exe_name;

void print_usage()
{
  fprintf(stderr, "Usage:\n");
  fprintf(stderr, "  %s <options> SIM_ARGS\n", g_sim_exe_name.c_str());
  fprintf(stderr, "options:\n");
  fprintf(stderr, "  --help - print this message\n");
  fprintf(stderr, "  --connect <from pkg> <from pin> <to pkg> <to pin> - connect a pair of pads together\n");
  fprintf(stderr, "  SIM_ARGS - the remaining arguments will be passed to the xsim created\n");
  exit(1);
}

#define FAIL_TX_TIMEOUT 0
#define FAIL_TX_TOOSHORT 1
#define FAIL_TX_MISMATCH 2

void fail(int failReason)
{
    switch (failReason)
    {
        case FAIL_TX_TIMEOUT:
            fprintf(stderr, "ERROR: Tx Timeout (Expected packet from XCore but did not receive within timeout\n");
            break;
        
        case FAIL_TX_TOOSHORT:
            fprintf(stderr, "ERROR: Tx Packed ended before expected\n");
            break;
        
        case FAIL_TX_MISMATCH:
            fprintf(stderr, "ERROR: Tx data mismatch\n");
            break;

    }
    fprintf(stderr, "Terminating due to Error\n");
    exit(1);
}


unsigned str_to_uint(const char *val_str, const char *description)
{
  char *end_ptr = 0;
  unsigned value = strtoul(val_str, &end_ptr, 0);

  if (strcmp(end_ptr, "") != 0) {
    fprintf(stderr, "ERROR: could not parse %s\n", description);
    print_usage();
  }
  
  return (unsigned)value;
}

int parse_connect(int argc, char **argv, int index)
{
  if ((index + 4) >= argc) {
    fprintf(stderr, "ERROR: missing arguments for --connect\n");
    print_usage();
  }

  //g_connections[g_num_connections].from_package = argv[index + 1];
  //g_connections[g_num_connections].from_pin     = argv[index + 2];
  //g_connections[g_num_connections].to_package   = argv[index + 3];
  //g_connections[g_num_connections].to_pin       = argv[index + 4];
  //g_num_connections++;
  return index + 5;
}

void parse_args(int argc, char **argv)
{
  g_sim_exe_name = argv[0];
  unsigned int char_index = g_sim_exe_name.find_last_of("\\/");
  if (char_index > 0)
    g_sim_exe_name.erase(0, char_index + 1);

  bool done = false;
  int index = 1;
  while (!done && (index < argc)) {
    if (strcmp(argv[index], "--help") == 0) {
      print_usage();

    //} else if (strcmp(argv[index], "--connect") == 0) {
    //  index = parse_connect(argc, argv, index);

    } 
    else {
      done = true;
    }
  }

  string args;
  while (index < argc) {
    args += " ";
    args += argv[index];
    index++;
  }

  XsiStatus status = xsi_create(&g_device, args.c_str());
  if (status != XSI_STATUS_OK) {
    fprintf(stderr, "ERROR: failed to create device with args '%s'\n", args.c_str());
    print_usage();
  }
}

bool is_pin_driving(const char *package, const char *pin)
{
  unsigned int is_driving = 0;
  XsiStatus status = xsi_is_pin_driving(g_device, package, pin, &is_driving);
  if (status != XSI_STATUS_OK) {
    fprintf(stderr, "ERROR: failed to check for driving pin %s on package %s\n", pin, package);
    exit(1);
  }
  return is_driving ? true : false;
}

unsigned sample_pin(const char *package, const char *pin)
{
  unsigned value = 0;
  XsiStatus status = xsi_sample_pin(g_device, package, pin, &value);
  if (status != XSI_STATUS_OK) {
    fprintf(stderr, "ERROR: failed to sample pin %s on package %s\n", pin, package);
    exit(1);
  }
  return value;
}

void drive_pin(const char *package, const char *pin, unsigned value)
{
  XsiStatus status = xsi_drive_pin(g_device, package, pin, value);
  if (status != XSI_STATUS_OK) {
    fprintf(stderr, "ERROR: failed to drive pin %s on package %s\n", pin, package);
    exit(1);
  }
}

void drive_port(const char *core, const char *port, XsiPortData mask, XsiPortData value)
{
    char *portString;

    if(strcmp(port, CLK_PORT) == 0)
    {
       portString = "CLK_PORT"; 
       fprintf(stdin, "TB: Driving %s : %x\n", portString, value);
       fprintf(stdout, "TB: Driving %s : %x\n", portString, value);
    }
    else
    {
        fprintf(stdout, "TB: Driving %s : %x\n", port, value);
    }


  XsiStatus status = xsi_drive_port_pins(g_device, core, port, mask,value);
  if (status != XSI_STATUS_OK) 
  {
    fprintf(stderr, "\nERROR: failed to drive port %s on core %s\n", port, core);
    exit(1);
  }
}


unsigned sample_port(const char *core, const char *port, XsiPortData mask)
{
    unsigned svalue = 0;

    XsiStatus status = xsi_sample_port_pins(g_device, core, port, mask, &svalue);

    //fprintf(stdout, "TB: Sampled %s : %x\n", port, svalue);

    if (status != XSI_STATUS_OK) 
    {
        fprintf(stderr, "ERROR: failed to sample port %s on core %s\n", port, core);
        exit(1);
    }
    return svalue;
}




int g_usbClock = 0;

/* USB State machine states */
typedef enum USBState {
                            START,
                            IN_DELAY, 
                            RX_DATA,
                            RX_TOKEN_DELAY1,
                            RX_TOKEN_DELAY2,
                            RX_TOKEN_DELAY3,
                            RX_TOKEN_EP1,
                            RX_TOKEN_EP2,
                            TX_DATA,
                            TX_DATA_WAIT,
                        };

USBState g_currentState;
int g_delayCount = 0;
int g_rxDataCount = 0;
int g_rxDataIndex = 0;

int g_txDataCount = 0;
int g_txDataIndex = 0;
int g_txTimeout = 0;

USBDelay *myUsbDelay;
USBRxPacket *myUsbRxPacket;
USBTxPacket *myUsbTxPacket;
USBRxToken *myUsbRxToken;

int stop = 0;

USBState usb_rising(USBState curState, node *head)
{
    node *temp1 = head; 
      
    USBState nextState = g_currentState;
    unsigned expectTxData = 0;

    /* Sample data from device on rising edge */
    unsigned txdRdyOut = sample_port("stdcore[0]", TX_RDY_OUT_PORT, 0xFF);
    unsigned txData = sample_port("stdcore[0]", TX_DATA_PORT, 0xFF);

    switch(curState)
    {
        case START:

            fprintf(stdout, "TB: in START: \n");
            
            /* Pop a usb event from the list */
            //if(head != NULL)
            if(!stop)
            {
                USBEvent *e1 = temp1->e;   

                /* Look for DELAY */
                myUsbDelay = dynamic_cast<USBDelay*>(e1); 
                myUsbRxPacket = dynamic_cast<USBRxPacket*>(e1);
                myUsbRxToken = dynamic_cast<USBRxToken*>(e1);
                myUsbTxPacket = dynamic_cast<USBTxPacket*>(e1);

                if(myUsbDelay)
                {
                    fprintf(stdout, "Read Delay (%d)\n", myUsbDelay->GetDelayTime());
            
                    nextState = IN_DELAY;
                    g_delayCount = myUsbDelay->GetDelayTime();
                }

                /* LOOK FOR RX PACKET */
                else if(myUsbRxPacket)
                {
                    fprintf(stdout, "Read RxPacket (length: %d): ", myUsbRxPacket->GetDataLength());
                    for(int i = 0; i < myUsbRxPacket->GetDataLength(); i++)
                    {
                        fprintf(stdout, "%x ", myUsbRxPacket->GetData(i));
                    } 
                    fprintf(stdout, "\n");
                
                    nextState = RX_DATA;
                    g_rxDataCount = myUsbRxPacket->GetDataLength();
                    g_rxDataIndex = 0;
                }
                else if(myUsbRxToken)
                {
                    fprintf(stdout, "Read RxToken (PID: %d, EP: %d)\n", myUsbRxToken->GetPid(), myUsbRxToken->GetEp());

                    nextState = RX_TOKEN_DELAY1;
                }
                else if(myUsbTxPacket)
                {
                    fprintf(stdout, "Read TxPacket (Length: %d, Timeout: %d): ", 
                            myUsbTxPacket->GetDataLength(), myUsbTxPacket->GetTimeout());

                    expectTxData = 1;

                    for(int i = 0; i < myUsbTxPacket->GetDataLength(); i++)
                    {
                        fprintf(stdout, "%x ", myUsbTxPacket->GetData(i));
                    } 
                    fprintf(stdout, "\n");

                    nextState = TX_DATA_WAIT;
                    g_txDataCount = myUsbTxPacket->GetDataLength();
                    g_txTimeout = myUsbTxPacket->GetTimeout();
                    g_txDataIndex = 0;                  
                    drive_port("stdcore[0]", V_TOK_PORT, 0x1, 0);
                    drive_port("stdcore[0]", RX_RXA_PORT, 0xFF, 0);
                    drive_port("stdcore[0]", RX_RXV_PORT, 0xFF, 0);
                    drive_port("stdcore[0]", RX_DATA_PORT, 0xFF, 0);


                }
                else
                {
                    printf("TB: UNKNOWN EVENT TYPE IN LIST!!\n");
                    while(1);

                }

                if(head->next == NULL)
                {
                        stop = 1;
                }
                else    
                {
                    *head = *head->next;   // tranfer the address of 'temp->next' to 'temp'
                }
            }
            else
            {
                fprintf(stdout, "END OF EVENT LIST\n");
                fprintf(stdout, "PASS PASS PASS PASS PASS PASS PASS PASS PASS PASS PASS\n");
                while(1);
            }           

            break;

        case IN_DELAY:

            fprintf(stdout, "TB: IN_DELAY (%d)\n", g_delayCount);

            drive_port("stdcore[0]", RX_RXA_PORT, 0x1, 0);
            drive_port("stdcore[0]", RX_RXV_PORT, 0x1, 0);
            //drive_port("stdcore[0]", V_TOK_PORT, 0x1, 0);
            drive_port("stdcore[0]", RX_DATA_PORT, 0xFF, 0x0);

            /* Reduce delay once per period (so every other usb_tick)*/
            if(g_usbClock == 1)
            {
                g_delayCount--;
                if(g_delayCount == 0)
                {
                    /* End of Delay.. go back to start and read new event*/
                    nextState = START;
                    fprintf(stdout, "TB: End of Delay\n\n");
                }
                else
                {
                    nextState = IN_DELAY;
                }
            }
            else
            {
                nextState = IN_DELAY;
            }
            break; 

        case RX_DATA:

            fprintf(stdout, "TB: RX_DATA %d : %d\n", g_rxDataIndex, myUsbRxPacket->GetData(g_rxDataIndex));
            nextState = RX_DATA;

            //drive_port("stdcore[0]", RX_DATA_PORT, 0xFF, myUsbRxPacket->GetData(g_rxDataIndex));

            // Change data on falling edge
            if(g_usbClock)
            {
                g_rxDataIndex++;
            }

            
            break; 

        case RX_TOKEN_DELAY1:
            break;  
        
         case RX_TOKEN_DELAY2:
            break; 
        
         case RX_TOKEN_DELAY3:
            break; 

        case RX_TOKEN_EP1:
            break;

        case RX_TOKEN_EP2:
            break;

        case TX_DATA_WAIT:
            {
            /* Waiting for TX DATA */
            fprintf(stdout, "TB: TX_DATA_WAIT Expecting: %x (Timeout: %d)\n", myUsbTxPacket->GetData(g_txDataIndex), g_txTimeout);
            nextState = TX_DATA_WAIT;

            expectTxData = 1;

            unsigned txVld = sample_port("stdcore[0]", TX_RDY_OUT_PORT, 0xFF);

            if(txVld)
            {

                unsigned char sample = sample_port("stdcore[0]", TX_DATA_PORT, 0xFF);
                fprintf(stdout, "TB: RECEIVED BYTE: %x : ", sample);

                if(sample == (unsigned)myUsbTxPacket->GetData(g_txDataIndex))
                {
                    fprintf(stdout, "MATCH\n");
                }
                else
                {
                    //fprintf(stdout, "ERROR!!\n");
                    //while(1);
                    fail(FAIL_TX_MISMATCH);
                }
                g_txDataIndex++;

                if(g_txDataIndex == g_txDataCount)
                {
                    nextState = START;
                }
                else
                {
                    nextState = TX_DATA;
                }
            }
            else
            {
                g_txTimeout--;
                if(g_txTimeout == 0)
                {
                    fail(FAIL_TX_TIMEOUT);
                }
            }
            }
            break;
        
        case TX_DATA:
        {
            /* TODO CHECK FOR PACKET ENDING EARLY */
            fprintf(stdout, "TB: TX_DATA\n");
           
            unsigned txVld = sample_port("stdcore[0]", TX_RDY_OUT_PORT, 0xFF);

            expectTxData = 1;

            if(txVld)
            {
                unsigned char sample = sample_port("stdcore[0]", TX_DATA_PORT, 0xFF);
                fprintf(stdout, "TB: RECEIVED BYTE: %x : ", sample);

                if(sample == (unsigned)myUsbTxPacket->GetData(g_txDataIndex))
                {
                    fprintf(stdout, "MATCH\n");
                }
                else
                {
                    fail(FAIL_TX_MISMATCH);
                }
                g_txDataIndex++;

                if(g_txDataIndex == g_txDataCount)
                {
                    nextState = START;
                }
                else
                {
                    nextState = TX_DATA;
                }
            }
            else
            {
                fail(FAIL_TX_TOOSHORT);
            }
           
            
            break; 
        }
        default:
            
            fprintf(stdout, "TB: UNKNOWN STATE: %d\n", g_currentState);
            break;
        
    }

    if(!expectTxData)
    {
        if(txdRdyOut!=0) /* TxData may be non-zero but we dont care do long as ReadyOut == 0 */
        { 
            fprintf(stdout, "TB: !!! ERROR: UNEXPECTED DATA FROM XCORE!!!\n");

            fprintf(stdout, "TB: TxReady High\n");

            if(txData != 0)
                fprintf(stdout, "TB: TxData != 0\n");
            
            while(1);
        }
    }

    return nextState;


}

USBState usb_falling(USBState curState)
{
    USBState nextState = curState;

    switch (curState)
    {
        case RX_TOKEN_DELAY1:

            /* Drive out start of token (PID) */
            drive_port("stdcore[0]", V_TOK_PORT, 0x1, 0);
            drive_port("stdcore[0]", RX_RXA_PORT, 0xFF, 1);
            drive_port("stdcore[0]", RX_RXV_PORT, 0xFF, 1);
            drive_port("stdcore[0]", RX_DATA_PORT, 0xFF, myUsbRxToken->GetPid());

            fprintf(stdout, "TB: RX_TOKEN_DELAY1\n");
            nextState = RX_TOKEN_DELAY2;
            break;  

        case RX_TOKEN_DELAY2:

            /* End of PID cycle */
            drive_port("stdcore[0]", RX_RXV_PORT, 0xFF, 0);
            drive_port("stdcore[0]", RX_DATA_PORT, 0xFF, 0);

            fprintf(stdout, "TB: RX_TOKEN_DELAY2\n");
            nextState = RX_TOKEN_DELAY3;
            break; 
        
        case RX_TOKEN_DELAY3:

            /* Cycle gap */

            fprintf(stdout, "TB: RX_TOKEN_DELAY3\n");
            nextState = RX_TOKEN_EP1;
            break; 

        case RX_TOKEN_EP1:

            /* Drive out EP number */
            /* Valid token high also */
            drive_port("stdcore[0]", RX_DATA_PORT, 0xFF, myUsbRxToken->GetEp());
            drive_port("stdcore[0]", RX_RXV_PORT, 0xFF, 1);
            drive_port("stdcore[0]", V_TOK_PORT, 0xFF, 1);
            
            nextState = RX_TOKEN_EP2;
            break;

         case RX_TOKEN_EP2:
            
            /* End of EP */
            drive_port("stdcore[0]", RX_RXV_PORT, 0xFF, 0);
            drive_port("stdcore[0]", RX_RXA_PORT, 0xFF, 0);
            drive_port("stdcore[0]", RX_DATA_PORT, 0xFF, 0);
            nextState = START;

            break;

        case RX_DATA:

            /* Drive out RX DATA on falling edge */
            drive_port("stdcore[0]", RX_DATA_PORT, 0xFF, myUsbRxPacket->GetData(g_rxDataIndex));

            drive_port("stdcore[0]", V_TOK_PORT, 0x1, 0);
            drive_port("stdcore[0]", RX_RXA_PORT, 0xFF, 1);
            drive_port("stdcore[0]", RX_RXV_PORT, 0xFF, 1);
            drive_port("stdcore[0]", RX_DATA_PORT, 0xFF, myUsbRxPacket->GetData(g_rxDataIndex));


            /* End of RX data */
            if(g_rxDataIndex == g_rxDataCount)
            {
                    /* Return to start state */
                    drive_port("stdcore[0]", RX_RXA_PORT, 0xFF, 0);
                    drive_port("stdcore[0]", RX_RXV_PORT, 0xFF, 0);
                    drive_port("stdcore[0]", RX_DATA_PORT, 0xFF, 0);
                    nextState = START;

                    fprintf(stdout, "TB: EN OF RX DATA\n");
            }
            break;

        default:

            break;

    }


    return nextState;

}





  

void usb_tick(node *head)
{

    node *temp1 = head; 
      
    USBState nextState = g_currentState;

    /* Toggle USB clock port */
    g_usbClock = !g_usbClock;

    drive_port("stdcore[0]", CLK_PORT, 0x1, g_usbClock);

    if(g_usbClock)
    {
        nextState = usb_rising(g_currentState, head);
    }
    else
    {
        nextState = usb_falling(g_currentState);
    }

    g_currentState = nextState;

}


XsiStatus sim_clock()
{
  XsiStatus status = xsi_clock(g_device);
  if ((status != XSI_STATUS_OK) && (status != XSI_STATUS_DONE)) {
    fprintf(stderr, "ERROR: failed to clock device (status %d)\n", status);
    exit(1);
  }
  return status;
}

void PrintUSBEventList(node *head)
{
    fprintf(stdout, "\nUSB Event List:\n");

    node *temp1 = head; 
      
    int x = 0;
 
    while(temp1 != NULL)
    {
        printf("EVENT %d: ", x);

        x++;
        
        USBEvent *e1 = temp1->e;   

        USBDelay * myUsbDelay = dynamic_cast<USBDelay*>(e1);
        
        if(myUsbDelay)
        {
            fprintf(stdout, "Delay (%d)\n", myUsbDelay->GetDelayTime());
        }

        USBRxPacket * myUsbRxPacket = dynamic_cast<USBRxPacket*>(e1);

        if(myUsbRxPacket)
        {
            fprintf(stdout, "RxPacket (length: %d): ", myUsbRxPacket->GetDataLength());
            for(int i = 0; i < myUsbRxPacket->GetDataLength(); i++)
            {
                fprintf(stdout, "%x ", myUsbRxPacket->GetData(i));
            } 
            fprintf(stdout, "\n");
        }

        USBRxToken * myUsbRxToken = dynamic_cast<USBRxToken*>(e1);
        
        if(myUsbRxToken)
        {
            fprintf(stdout, "RxToken (PID: %d, EP: %d)\n", myUsbRxToken->GetPid(), myUsbRxToken->GetEp());
        }

        temp1 = temp1->next;   // transfer the address of 'temp->next' to 'temp'
    }

    printf("Done\n");
}

void AddUSBEventToList(node **head, USBEvent *e)
{
    node *temp;             //create a temporary node 
    temp = (node*)malloc(sizeof(node)); //allocate space for  

    temp->e = e;             // store data(first field)
    temp->next=*head;  // store the address of the pointer head(second field)
    *head = temp;
}


void AddList(testnode **testhead, int i)
{
 testnode *temp;             //create a temporary node 
        temp = (testnode*)malloc(sizeof(testnode)); //allocate space for node 

        temp->data = i;             // store data(first field)
        temp->next=*testhead;  // store the address of the pointer head(second field)
        *testhead = temp;                  // transfer the address of 'temp' to 'head' 


}

 
#define RX_DATALENGTH 10
#define RX_PKTLENGTH (RX_DATALENGTH+3)

int counter = 0;
unsigned char g_txDataVal = 1;
unsigned char g_rxDataVal = 1;

unsigned char g_pidTableIn[16];
unsigned char g_pidTableOut[16];

//eventIndex = AddInTransfer(UsbEventList, eventIndex, 1, 10);
/* TODO:
 * - timeout value
 * - Could take a hex value for handshake not 1 or 0 (0 would mean none)
 */
int AddInTransfer(USBEvent **UsbEventList, int eventIndex, int epNum, int length, int handshake)
{
    unsigned char *data = new unsigned char[length];
    unsigned char *packet = new unsigned char[length+3]; /* +3 for PID and CRC */
    unsigned char *dataAck = new unsigned char[1];
    dataAck[0] = PID_ACK;

    /* Populate expected data */
    for (int i = 0; i< length; i++)
    {
        data[i] = g_txDataVal++;
    }

    /* Create good CRC */
    unsigned crc = GenCrc16(data, length);

    /* PID and toggle*/
    packet[0] = g_pidTableIn[epNum];
    g_pidTableIn[epNum] ^= 0x88;
   
    for(int i = 0; i < length; i++)
    {
        packet[i+1] = data[i];
    }
    
    packet[length+1] = crc & 0xff;
    packet[length+2] = (crc>>8);

    /* Token: TB -> XCore */ 
    UsbEventList[eventIndex++] = new USBRxToken(PID_IN, epNum);

    /* Data: XCore -> TB */
    UsbEventList[eventIndex++] = new USBTxPacket(length+3, packet, 200);
 
    UsbEventList[eventIndex++] = new USBDelay(15);

    if(handshake)
    {
        UsbEventList[eventIndex++] = new USBRxPacket(1, dataAck);
    }
    else
    {
        g_txDataVal-=length;
    }
    return eventIndex;
}

int AddOutTransfer(USBEvent **UsbEventList, int eventIndex, int epNum, int length, int badCrc)
{
     unsigned char *data = new unsigned char[length];
    unsigned char *packet = new unsigned char[length+3]; /* +3 for PID and CRC */
    unsigned char *dataAck = new unsigned char[1];
    dataAck[0] = PIDn_ACK;

    /* Populate expected data */
    for (int i = 0; i< length; i++)
    {
        data[i] = g_rxDataVal++;
    }

    /* Create good CRC */
    unsigned crc = GenCrc16(data, length);

    /* PID and toggle */
    packet[0] = g_pidTableOut[epNum];
    g_pidTableOut[epNum] ^= 0x88;
    
    for(int i = 0; i < length; i++)
    {
        packet[i+1] = data[i];
    }
 
    if(!badCrc)
    {   
        packet[length+1] = crc & 0xff;
        packet[length+2] = (crc>>8);
    }

    UsbEventList[eventIndex++] = new USBRxToken(PID_OUT,epNum);
    UsbEventList[eventIndex++] = new USBDelay(40);
    UsbEventList[eventIndex++] = new USBRxPacket(length+3, packet); /* +3 for PID and CRC */

    if(!badCrc)
    {
        UsbEventList[eventIndex++] = new USBTxPacket(1, dataAck, 30);
    }
    else
    {
        /* If CRC is bad then dont expect handshake.  We need to resend */
        g_rxDataVal -= length;
    }


    return eventIndex;
}
int main(int argc, char **argv)
{
    parse_args(argc, argv);

    //fprintf(stdout, "Running XUD testbench\n");

    // Empty linked list
    node *head = NULL;

    /* Init port state */
    drive_port("stdcore[0]", RX_RXA_PORT, 0x1, 0);
    drive_port("stdcore[0]", RX_RXV_PORT, 0x1, 0);
    drive_port("stdcore[0]", V_TOK_PORT, 0x1, 0);
    drive_port("stdcore[0]", RX_DATA_PORT, 0xFF, 0x0);
    drive_port("stdcore[0]", TX_RDY_IN_PORT, 0xFF, 0x1);

    /* Create test datapacket */
    unsigned char *data;
    unsigned char *dataPacket;
    data = new unsigned char[RX_DATALENGTH];
    dataPacket = new unsigned char[RX_PKTLENGTH];

    unsigned char *dataNak = new unsigned char[1];
    unsigned char *dataAck = new unsigned char[1];
    dataNak[0] = 0x5a;
    dataAck[0] = 0xd2;
    int len = 0;
    int ep  = 0;
    int handshake = 1;

    for (int i = 0; i < 16; i++)
    {
        g_pidTableIn[i] = PIDn_DATA0;
        g_pidTableOut[i] = PIDn_DATA0;
    }
    
    int eventIndex = 0;   

    /* Bad CRC*/
    for (int i = 0; i < RX_DATALENGTH; i++)
    {
        data[i] = i+1; 
    }

    /* GOOD CRC TEST */
    unsigned crc = GenCrc16(data, RX_DATALENGTH);

    dataPacket[0] = PIDn_DATA0;
    for(int i = 0; i < RX_DATALENGTH; i++)
    {
        dataPacket[i+1] = data[i];
    }

#if (TEST_ACK) || (TEST_NAK)
    dataPacket[RX_PKTLENGTH-2] = crc & 0xff;
    dataPacket[RX_PKTLENGTH-1] = (crc>>8);
#endif

#define NUM_EVENTS 100
    USBEvent *UsbEventList[NUM_EVENTS];

    /* Create test packet list */
    UsbEventList[eventIndex++] = new USBDelay(1200);
    
    eventIndex = AddOutTransfer(UsbEventList, eventIndex, 1, RX_DATALENGTH, 0); /* EP, Length */

    UsbEventList[eventIndex++] = new USBDelay(500);

    eventIndex = AddInTransfer(UsbEventList, eventIndex, 1, RX_DATALENGTH, 1); /* EP, Length */

    UsbEventList[eventIndex++] = new USBDelay(50);
    eventIndex = AddOutTransfer(UsbEventList, eventIndex, 1, RX_DATALENGTH, 0); /* EP, Length */
    UsbEventList[eventIndex++] = new USBDelay(500);
    eventIndex = AddInTransfer(UsbEventList, eventIndex, 1, RX_DATALENGTH, 0); /* EP, Length */

    UsbEventList[eventIndex++] = new USBDelay(300);
    eventIndex = AddOutTransfer(UsbEventList, eventIndex, 1, 20, 0); /* EP, Length */
    UsbEventList[eventIndex++] = new USBDelay(500);
    eventIndex = AddInTransfer(UsbEventList, eventIndex, 1, RX_DATALENGTH,  1); /* EP, Length, badcrc, handshake */

    UsbEventList[eventIndex++] = new USBDelay(50);
    eventIndex = AddOutTransfer(UsbEventList, eventIndex, 1, 10, 1); /* EP, Length */
  
    len = 11;
    UsbEventList[eventIndex++] = new USBDelay(50);
    eventIndex = AddOutTransfer(UsbEventList, eventIndex, 1, len, 0); /* EP, Length */
    UsbEventList[eventIndex++] = new USBDelay(50);
    eventIndex = AddInTransfer(UsbEventList, eventIndex, 1, 20,  1); /* EP, Length, handshake */
    UsbEventList[eventIndex++] = new USBDelay(50);
    eventIndex = AddInTransfer(UsbEventList, eventIndex, 1, len,  1); /* EP, Length, handshake */

    /* ISO ep tests - no handshaking */
    ep = 2;
    handshake = 0;
    UsbEventList[eventIndex++] = new USBDelay(50);
    eventIndex = AddOutTransfer(UsbEventList, eventIndex, ep, len, handshake); /* EP, Length */
    UsbEventList[eventIndex++] = new USBDelay(50);
    eventIndex = AddInTransfer(UsbEventList, eventIndex, ep, len,  handshake); /* EP, Length, handshake */
    UsbEventList[eventIndex++] = new USBDelay(50);
    eventIndex = AddInTransfer(UsbEventList, eventIndex, ep, len, handshake); /* EP, Length, handshake */



    /* Must give enough delay for exit() on xcore to run .. this is a TODO item */
    UsbEventList[eventIndex++] = new USBDelay(500);

    for(int i = eventIndex-1; i >= 0; i--)
    {
        AddUSBEventToList(&head, UsbEventList[i]);
    }    

    PrintUSBEventList(head);

    printf("\nRunning Sim...\n");
        

    int time = 0;

    bool done = false;
    while (!done) 
    {
        XsiStatus status = sim_clock();
        if (status == XSI_STATUS_DONE)
        {
            done = true;
        }
    
        time++;

        // USB tick every 8 sim ticks
        if(time == 8)
        {
            time = 0;
            usb_tick(head);
        }

   
    }

  XsiStatus status = xsi_terminate(g_device);
  if (status != XSI_STATUS_OK) {
    fprintf(stderr, "ERROR: failed to terminate device\n");
    exit(1);
  }
  return 0;
}
