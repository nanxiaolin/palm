function varargout = driftcorrection(varargin)
%DRIFTCORRECTION MATLAB code file for driftcorrection.fig
%      DRIFTCORRECTION, by itself, creates a new DRIFTCORRECTION or raises the existing
%      singleton*.
%
%      H = DRIFTCORRECTION returns the handle to a new DRIFTCORRECTION or the handle to
%      the existing singleton*.
%
%      DRIFTCORRECTION('Property','Value',...) creates a new DRIFTCORRECTION using the
%      given property value pairs. Unrecognized properties are passed via
%      varargin to driftcorrection_OpeningFcn.  This calling syntax produces a
%      warning when there is an existing singleton*.
%
%      DRIFTCORRECTION('CALLBACK') and DRIFTCORRECTION('CALLBACK',hObject,...) call the
%      local function named CALLBACK in DRIFTCORRECTION.M with the given input
%      arguments.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help driftcorrection

% Last Modified by GUIDE v2.5 08-Feb-2020 10:53:53

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @driftcorrection_OpeningFcn, ...
                   'gui_OutputFcn',  @driftcorrection_OutputFcn, ...
                   'gui_LayoutFcn',  [], ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
   gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before driftcorrection is made visible.
function driftcorrection_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   unrecognized PropertyName/PropertyValue pairs from the
%            command line (see VARARGIN)

% Choose default command line output for driftcorrection
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes driftcorrection wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = driftcorrection_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on selection change in lstFiducials.
function lstFiducials_Callback(hObject, eventdata, handles)
% hObject    handle to lstFiducials (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns lstFiducials contents as cell array
%        contents{get(hObject,'Value')} returns selected item from lstFiducials


% --- Executes during object creation, after setting all properties.
function lstFiducials_CreateFcn(hObject, eventdata, handles)
% hObject    handle to lstFiducials (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in btnFind.
function btnFind_Callback(hObject, eventdata, handles)
% hObject    handle to btnFind (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in btnApply.
function btnApply_Callback(hObject, eventdata, handles)
% hObject    handle to btnApply (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in btnPick.
function btnPick_Callback(hObject, eventdata, handles)
% hObject    handle to btnPick (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in btnUnpick.
function btnUnpick_Callback(hObject, eventdata, handles)
% hObject    handle to btnUnpick (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in btnUnapply.
function btnUnapply_Callback(hObject, eventdata, handles)
% hObject    handle to btnUnapply (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



function edMSD_Callback(hObject, eventdata, handles)
% hObject    handle to edMSD (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edMSD as text
%        str2double(get(hObject,'String')) returns contents of edMSD as a double


% --- Executes during object creation, after setting all properties.
function edMSD_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edMSD (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function DCstatus_Callback(hObject, eventdata, handles)
% hObject    handle to DCstatus (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of DCstatus as text
%        str2double(get(hObject,'String')) returns contents of DCstatus as a double


% --- Executes during object creation, after setting all properties.
function DCstatus_CreateFcn(hObject, eventdata, handles)
% hObject    handle to DCstatus (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
