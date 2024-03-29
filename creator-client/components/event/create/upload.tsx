import { css } from '@emotion/react';
import { ActionCreatorWithPayload } from '@reduxjs/toolkit';
import {
  ChangeEvent,
  ChangeEventHandler,
  FunctionComponent,
  useEffect,
  useRef,
  useState,
} from 'react';
import { useDispatch } from 'react-redux';
import { FileType } from '../../../types/common';
import EventCreateItemWrapper from './item-wrapper';
interface EventCreateUploadProps {
  title: string;
  action: ActionCreatorWithPayload<FileType>;
}

const EventCreateUpload: FunctionComponent<EventCreateUploadProps> = ({ title, action }) => {
  const [imageUrl, setImageUrl] = useState<string>('');
  const uploadRef = useRef<HTMLInputElement>(null);
  const wrapRef = useRef<HTMLDivElement>(null);
  const [imageHeight, setImageHeight] = useState<number>(0);
  const dispatch = useDispatch();

  const screenResize = () => {
    setImageHeight(() => ((wrapRef.current?.clientWidth ?? 0) / 16) * 9);
  };

  useEffect(() => {
    screenResize();
    window.addEventListener('resize', screenResize);
    return () => {
      window.removeEventListener('resize', screenResize);
    };
  }, []);

  const uploadHandler: ChangeEventHandler = (event: ChangeEvent<HTMLInputElement>) => {
    if (!event.target.files || event.target.files?.length === 0) return;
    const url = URL.createObjectURL(event.target.files[0]);
    setImageUrl(() => url);
    dispatch(
      action({
        url: url,
        file: event.target.files[0],
      })
    );
  };

  const wrapperStyle = css`
    position: relative;
    width: 100%;
    height: ${imageHeight}px;
    border: 1px solid black;
    ${imageUrl === '' ? undefined : `background-image: url(${imageUrl});`}
    background-size: contain;
    background-repeat: no-repeat;
    background-position: center;
    border-radius: 10px;
    overflow: hidden;
    > button {
      display: none;
    }

    :hover {
      > button {
        display: block;
      }
    }
  `;

  const buttonStyle = css`
    position: absolute;
    font-size: 30px;
    top: 0;
    bottom: 0;
    left: 0;
    right: 0;
    background-image: url('/static/add-image.png');
    background-size: 20%;
    background-repeat: no-repeat;
    background-position: center;
    border: none;
    opacity: 0.5;
  `;

  return (
    <EventCreateItemWrapper title={title + ' 업로드'}>
      <div css={wrapperStyle} ref={wrapRef}>
        <button
          css={buttonStyle}
          onClick={() => {
            uploadRef.current?.click();
          }}
        ></button>

        <input
          style={{ display: 'none' }}
          ref={uploadRef}
          type="file"
          accept="image/*"
          onChange={uploadHandler}
          multiple={false}
        ></input>
      </div>
    </EventCreateItemWrapper>
  );
};

export default EventCreateUpload;
