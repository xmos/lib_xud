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

/* TODO List*/
/*
 * - Ideally RXA done properly - requires two more states using RxAStartDelay and RxAEndDelay
 * - RxV bubbles in packets
 */

#define MAX_INSTANCES 256

/* All port names relative to Xcore */
#define CLK_PORT        "XS1_PORT_1A"

#define RX_DATA_PORT    "XS1_PORT_8A"
#define RX_RXA_PORT     "XS1_PORT_1D"
#define RX_RXV_PORT     "XS1_PORT_1C"

#define V_TOK_PORT      "XS1_PORT_1E" 

using namespace std;

typedef enum USBEventType { tx, rx, delay, tok};

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
  XsiStatus status = xsi_drive_port_pins(g_device, core, port, mask,value);
  if (status != XSI_STATUS_OK) 
  {
    fprintf(stderr, "\nERROR: failed to drive port %s on core %s\n", port, core);
    exit(1);
  }
}

int g_usbClock = 0;

/* USB State machine states */
typedef enum USBState {
                            START,
                            IN_DELAY, 
                            RX_DATA,
                        };

USBState g_currentState;
int g_delayCount = 0;
int g_rxDataCount = 0;
int g_rxDataIndex = 0;

USBDelay *myUsbDelay;
USBRxPacket *myUsbRxPacket;
  
int stop = 0;

void usb_tick(node *head)
{

    node *temp1 = head; 
      
    USBState nextState = START;

    /* Toggle USB clock port */
    g_usbClock = !g_usbClock;

    drive_port("stdcore[0]", CLK_PORT, 0x1, g_usbClock);
 
    printf("TB: CLK: %d: ", g_usbClock);
   
    switch(g_currentState)
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

                if(myUsbDelay)
                {
                    fprintf(stdout, "Read Delay (%d)\n", myUsbDelay->GetDelayTime());
            
                    nextState = IN_DELAY;
                    g_delayCount = myUsbDelay->GetDelayTime();
                    /* move on down the list... */
                    //*head = *head->next;   // tranfer the address of 'temp->next' to 'temp'

                }

                /* LOOK FOR RX PACKET */
                myUsbRxPacket = dynamic_cast<USBRxPacket*>(e1);

                if(myUsbRxPacket)
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

                   
                    drive_port("stdcore[0]", RX_RXA_PORT, 0xFF, 1);
                    drive_port("stdcore[0]", RX_RXV_PORT, 0xFF, 1);
                    drive_port("stdcore[0]", RX_DATA_PORT, 0xFF, myUsbRxPacket->GetData(g_rxDataIndex));
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
                while(1);
            }           

            break;

        case IN_DELAY:

            fprintf(stdout, "TB: IN_DELAY (%d)\n", g_delayCount);

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

            drive_port("stdcore[0]", RX_DATA_PORT, 0xFF, myUsbRxPacket->GetData(g_rxDataIndex));

            // Change data on on falling edge
            if(g_usbClock == 1)
            {
                g_rxDataIndex++;

            }

            /* End of RX data */
            if((g_rxDataIndex == g_rxDataCount) && (g_usbClock ==0))
            {
                    /* Return to start state */
                    drive_port("stdcore[0]", RX_RXA_PORT, 0xFF, 0);
                    drive_port("stdcore[0]", RX_RXV_PORT, 0xFF, 0);
                    drive_port("stdcore[0]", RX_DATA_PORT, 0xFF, 0);
                    nextState = START;
            }


            break;   

        default:
            
            fprintf(stdout, "TB: UNKNOWN STATE: %d\n", g_currentState);
            break;
        
    }

    if(nextState < 10)
    {

    }
    else
    {
        
            fprintf(stdout, "TB: nextState gone bad: %d\n", nextState);
            while(1);
    }

    /* Update state */
    g_currentState = nextState;    
 
    if(g_usbClock)
    {
        // Clock gone high

    }
    else
    {
        // Clock gone low

    }

}

#if 0
void manage_connections()
{
  for (size_t connection_num = 0; connection_num < g_num_connections; connection_num++) {
    const char *from_package = g_connections[connection_num].from_package;
    const char *from_pin     = g_connections[connection_num].from_pin;
    const char *to_package   = g_connections[connection_num].to_package;
    const char *to_pin       = g_connections[connection_num].to_pin;
    unsigned value = 0;
  
    int from_driving = is_pin_driving(from_package, from_pin);
    int to_driving = is_pin_driving(to_package, to_pin);
 
    drive_port("stdcore[0]", "XS1_PORT_8A", 0xff, 3);
    
    if (from_driving) 
    {
      value = sample_pin(from_package, from_pin);
      //drive_pin(to_package, to_pin, value);
      //drive_port("stdcore[0]", "XS1_PORT_8A", 8, 1);

    } else if (to_driving) {
      value = sample_pin(to_package, to_pin);
      drive_pin(from_package, from_pin, value);
      
    } else {
      // Read both in order to stop the testbench driving
    	sample_pin(from_package, from_pin);
    	sample_pin(to_package, to_pin);
    }
  }
}
#endif

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

        temp1 = temp1->next;   // tranfer the address of 'temp->next' to 'temp'
    }

    printf("Done\n");
}

void AddUSBEventToList(node **head, USBEvent *e)
{
    



    USBDelay * myUsbDelay = dynamic_cast<USBDelay*>(e);

    if(myUsbDelay)
    {
        //fprintf(stdout, "Adding delay (%d) to list\n", myUsbDelay->GetDelayTime());
    }

    USBRxPacket * myUsbRxPacket = dynamic_cast<USBRxPacket*>(e);

    if(myUsbRxPacket)
    {
        //fprintf(stdout, "Adding RxPacket (length: %d) to list\n", myUsbRxPacket->GetDataLength());
    }


#if 1
    node *temp;             //create a temporary node 
    temp = (node*)malloc(sizeof(node)); //allocate space for  

    temp->e = e;             // store data(first field)
    temp->next=*head;  // store the address of the pointer head(second field)
    *head = temp;
#else
    node **temp1;                         // create a temporary node
    temp1=(node**)malloc(sizeof(node));   // allocate space for node
    temp1 = head;                  // transfer the address of 'head' to 'temp1'
    int x = 0;
    while(*temp1->next!=NULL) // go to the last node
    {
        temp1 = temp1->next;//tranfer the address of 'temp1->next' to 'temp1'
        printf("%d\n", x);
    }

node *temp;                           // create a temporary node
temp = (node*)malloc(sizeof(node));  // allocate space for node
temp->e = e;                   // store data(first field)
temp->next = NULL;                   // second field will be null(last node)
temp1->next = temp;                  // 'temp' node will be the last node
  
#endif 
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

int main(int argc, char **argv)
{
    parse_args(argc, argv);

    fprintf(stdout, "Running XUD testbench\n");
 
    // Empty linked list
    node *head = NULL;

    /* Init port state */
    drive_port("stdcore[0]", RX_RXA_PORT, 0x1, 0);
    drive_port("stdcore[0]", RX_RXV_PORT, 0x1, 0);
    drive_port("stdcore[0]", RX_DATA_PORT, 0xFF, 0xFF);


    /* Create test datapacket */
    unsigned char *data;
    data = new unsigned char[RX_DATALENGTH];
    
    for (int i = 0; i < RX_DATALENGTH; i++)
    {
        data[i] = i*2; 
    }

    /* Create test packet list */
    USBEvent *test0 = new USBDelay(20);
    USBEvent *test1 = new USBRxPacket(RX_DATALENGTH, data);
    USBEvent *test2 = new USBDelay(20);
 

    AddUSBEventToList(&head, test0);
    AddUSBEventToList(&head, test1);
    AddUSBEventToList(&head, test2);

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

        // USB tick every 16/17 sim ticks
        if(time == 17)
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
